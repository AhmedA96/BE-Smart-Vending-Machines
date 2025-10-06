# frozen_string_literal: true

module Avo
  module Resources
    class PaymentMethodTranslation < Avo::BaseResource
      # self.includes = []
      # self.attachments = []
      # self.search = {
      #   query: -> { query.ransack(id_eq: q, m: "or").result(distinct: false) }
      # }

      def fields
        field :id, as: :id
      end
    end
  end
end
