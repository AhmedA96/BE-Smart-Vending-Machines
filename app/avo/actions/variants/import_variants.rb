# frozen_string_literal: true

module Avo
  module Actions
    module Variants
      class ImportVariants < Avo::BaseAction
        self.name = 'Import Variants'
        self.message = 'Import variants from Excel file'
        self.confirm_button_label = 'Import'
        self.cancel_button_label = 'Cancel'
        self.no_confirmation = false
        self.standalone = true

        def fields
          field :file, as: :file,
                       help: 'Upload Excel file (.xlsx or .xls) with variant data',
                       placeholder: 'Choose Excel file...'
          field :allow_updates, as: :boolean,
                                help: 'Allow updating existing variants',
                                default: false
        end

        def handle(**args) # rubocop:disable Metrics/CyclomaticComplexity
          fields = args[:fields] || args[:arguments] || {}
          file = fields['file'] || fields[:file]
          allow_updates = fields['allow_updates'] || fields[:allow_updates]

          return error 'Please select a file to import' if file.blank?

          options = {
            allow_updates: allow_updates || false
          }

          begin
            VariantsSheets::Import.call(file, options)

            succeed 'Variants imported successfully!'
          rescue StandardError => e
            Rails.logger.error "Import failed: #{e.message}"
            Rails.logger.error e.backtrace.join("\n")
            error "Import failed: #{e.message}"
          end
        end
      end
    end
  end
end
