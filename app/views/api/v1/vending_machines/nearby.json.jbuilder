# frozen_string_literal: true

json.message @vending_machines.any? ? 'Machines found' : 'No machines nearby'
json.machines @vending_machines do |machine|
  json.merge! machine.as_nearby_json
end
