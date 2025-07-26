# frozen_string_literal: true

class SupplierApiError < StandardError
  attr_reader :supplier_type, :context

  def initialize(message, supplier_type: nil, context: nil)
    @supplier_type = supplier_type
    @context = context
    super(message)
  end
end

class UnsupportedSupplierError < StandardError; end
