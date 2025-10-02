# frozen_string_literal: true

json.extract! category, :id, :name, :presentation, :description

if category.logo.attached?
  json.logo_url url_for(category.logo)
else
  json.logo_url nil
end
