# frozen_string_literal: true

class FailedRequestError < StandardError
  attr_reader :data

  def initialize(message, data = {})
    message = '' if message.nil?

    super(message)
    @data = data
  end
end

module ErrorHandling
  extend ActiveSupport::Concern

  included do
    rescue_from ::ActiveRecord::RecordInvalid, with: :render_unprocessable_content_response
    rescue_from ::ActiveRecord::RecordNotFound, with: :render_not_found_response
    rescue_from FailedRequestError, with: :request_error
    rescue_from Doorkeeper::Errors::InvalidToken, with: :request_error
  end

  def render_error(exception, status)
    @errors = exception.respond_to?(:record) ? exception.record.errors : [exception]

    render 'api/v1/shared/error', status:
  end

  def render_unprocessable_content_response(exception)
    render_json(:unprocessable_content, { message: exception.record.errors.full_messages.join(', ') })
  end

  def render_not_found_response(exception)
    render_json(:not_found, { message: I18n.t('errors.not_found', model: exception.model, id: exception.id) })
  end

  def request_error(exception)
    error_response = { message: exception.message }

    error_response.merge!(exception.data) if exception.respond_to?(:data) && exception.data.present?

    render_json(:bad_request, error_response)
    nil
  end

  def render_json(code, data = [])
    code = status_code(code)

    if code.to_s.start_with?('2')
      render json: { code: code, status: 'success', data: data, error: [] }, status: code
    else
      normalized_error = data.is_a?(Hash) ? data : { message: Array(data).join(', ') }
      render json: { code: code, status: 'failure', data: [], error: normalized_error }, status: code
    end
  end

  def status_code(code)
    code.is_a?(Symbol) ? Rack::Utils::SYMBOL_TO_STATUS_CODE[code] : code
  end
end
