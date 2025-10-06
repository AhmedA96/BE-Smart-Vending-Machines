# frozen_string_literal: true

module Products
  module PriceListFindable
    extend ActiveSupport::Concern

    included do
      before_action :find_machine
      before_action :find_price_list,
                    only: %i[index show]
    end

    private

    def find_price_list
      @price_list = machine_price_list
    end

    def find_machine
      @machine = Machine.find_by(id: params.dig(:q, :machine_id))
    end

    def machine_price_list
      @machine&.price_list
    end
  end
end
