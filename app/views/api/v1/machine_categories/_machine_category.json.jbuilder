# frozen_string_literal: true

json.extract! machine_category, :id, :name, :presentation, :description

if machine_category.logo.attached?
  json.logo_url url_for(machine_category.logo)
else
  json.logo_url nil
end

json.machines machine_category.machines do |machine|
  json.id machine.id
  json.name machine.presentation

  json.location do
    json.id machine.location.id
    json.name machine.location.name
  end
end
