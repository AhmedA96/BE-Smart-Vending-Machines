# frozen_string_literal: true

module Suppliers
  module Vendlife
    class MachineManager
      def initialize(client)
        @client = client
      end

      def get_machines(machineuuid = nil)
        params = {}
        params[:machineUuid] = machineuuid if machineuuid

        @client.make_request(:get, '/machineinfo/querymachineinfo', params)
      end

      def get_machine_status(machineuuid)
        params = { machineUuid: machineuuid }
        @client.make_request(:get, '/machineinfo/qrealnetstat', params)
      end

      def sync_machine_data(machine)
        machine_data = get_machines(machine.machineuuid)

        return if machine_data['data'].blank?

        data = machine_data['data'].first
        machine.update!(
          name: data['machineName'],
          status: map_vendlife_status(data['isActive'], data['onlineState']),
          installed_at: parse_datetime(data['actTime']),
          last_service_date: Time.current
        )

        # Update machine status record
        machine.machine_statuses.create!(
          status: machine.status
        )
      end

      def get_cabinet_temperature_humidity(machineuuid, cabinet_id)
        params = {
          machineUuid: machineuuid,
          equId: cabinet_id
        }

        @client.make_request(:get, '/machineequipment/queryEquHumiture', params)
      end

      def update_price_tags(machineuuid, cabinet_price_list)
        payload = {
          machineUuid: machineuuid,
          cabinetPriceList: cabinet_price_list
        }

        @client.make_request(:put, '/commodityinfo/updatePriceCodeCard', {}, payload)
      end

      private

      def map_vendlife_status(is_active, online_state)
        return 'Inactive' unless is_active == 1

        case online_state
        when 1 then 'Active'
        when 0 then 'Inactive'
        else 'Maintenance'
        end
      end

      def parse_datetime(datetime_string)
        return nil if datetime_string.blank?

        Time.zone.parse(datetime_string)
      rescue ArgumentError
        nil
      end
    end
  end
end
