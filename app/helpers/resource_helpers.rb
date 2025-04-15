# frozen_string_literal: true

module ResourceHelpers
  include Pundit::Authorization

  delegate :admin?, to: :current_user
end
