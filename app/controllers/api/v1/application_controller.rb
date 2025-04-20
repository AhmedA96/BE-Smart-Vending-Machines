# frozen_string_literal: true

module Api
  module V1
    class ApplicationController < ActionController::Base
      include ErrorHandling
      include Localization
      include Pagy::Backend
    end
  end
end
