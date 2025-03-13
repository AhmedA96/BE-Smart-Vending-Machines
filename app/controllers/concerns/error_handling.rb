# frozen_string_literal: true

module ErrorHandling
  extend ActiveSupport::Concern

  included do
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
end
