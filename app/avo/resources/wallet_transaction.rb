# frozen_string_literal: true

module Avo
  module Resources
    class WalletTransaction < Avo::BaseResource
      include ResourceHelpers

      self.includes = %i[wallet]

      def fields
        field :id, as: :id
        field :currency, as: :text, name: 'Wallet', only_on: %i[index]
        limited_field :wallet, as: :belongs_to, searchable: true, hide_on: :display
        field :amount, as: :number, required: true
        field :created_at, as: :date_time, only_on: %i[index show],
                           format: 'yyyy-LL-dd T a',
                           time_24hr: false,
                           filterable: true
      end
    end
  end
end
