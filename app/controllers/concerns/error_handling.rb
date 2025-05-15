# frozen_string_literal: true

module ErrorHandling
  extend ActiveSupport::Concern

  included do
    rescue_from Orders::OrderError, with: :handle_unprocessable_entity
    rescue_from Stock::StockError, with: :handle_unprocessable_entity
    rescue_from ActiveRecord::RecordInvalid, with: :render_invalid
    rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
  end

  def render_error(error, status)
    @errors = error.respond_to?(:record) ? error.record.errors : [error]

    render 'api/v1/shared/error', status:
  end

  def render_invalid(error)
    render_error(error, :unprocessable_entity)
  end

  def handle_unprocessable_entity(error)
    render_error(error, :unprocessable_entity)
  end

  def render_not_found(error)
    render_error(I18n.t('errors.not_found', model: error.model, id: error.id), :not_found)
  end
end
