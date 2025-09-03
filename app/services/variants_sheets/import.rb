# frozen_string_literal: true

require 'tempfile'
require 'roo'

module VariantsSheets
  class Import
    attr_reader :sheet, :file, :options

    def self.call(file, options = {})
      new(file, options).call
    end

    def initialize(file, options = {})
      @file = file
      @options = options.with_indifferent_access
      @sheet = load_sheet
    end

    def call
      sheet.each_row_streaming(pad_cells: true, offset: 1) do |row|
        row_values = row.map { |cell| cell.nil? ? '' : cell.value.to_s.strip }

        # Skip empty rows - check if SKU column is empty
        next if row_values[columns[:sku]].blank?

        process_variant_row(row_values)
      end
    end

    private

    def load_sheet
      file_content = file.respond_to?(:read) ? file.read : File.read(file.path)

      Tempfile.create(['variants_sheet', file_extension], encoding: 'BINARY') do |tempfile|
        tempfile.binmode
        tempfile.write(file_content)
        tempfile.rewind

        case file_extension
        when '.xlsx'
          Roo::Excelx.new(tempfile.path)
        when '.xls'
          Roo::Excel.new(tempfile.path)
        else
          raise "Unsupported file format: #{file_extension}"
        end
      end
    end

    def process_variant_row(row_values)
      variant_data = extract_variant_data(row_values)

      variant = Variant.find_by(sku: variant_data[:sku]) || Variant.new
      variant.assign_attributes(variant_data.compact)
      variant.save!
    end

    def extract_variant_data(row_values)
      data = {}

      columns.each do |attribute, index|
        value = row_values[index]
        data[attribute] = sanitize_value(attribute, value) if value.present?
      end

      data
    end

    def sanitize_value(column, value)
      case column
      when :cost_price, :weight
        value.to_f
      when :position, :points, :product_id
        value.to_i
      when :active, :is_master
        %w[true 1 yes].include?(value.to_s.downcase)
      when :sku
        value.to_s.strip.upcase
      else
        value.to_s.strip
      end
    end

    def columns
      VariantsSheets::Columns.call
    end

    def file_extension
      @file_extension ||= if file.respond_to?(:original_filename) && file.original_filename
                            File.extname(file.original_filename).downcase
                          elsif file.respond_to?(:path)
                            File.extname(file.path).downcase
                          elsif file.respond_to?(:tempfile)
                            # For uploaded files via forms
                            File.extname(file.tempfile.path).downcase
                          else
                            '.xlsx' # default fallback
                          end
    end
  end
end
