# frozen_string_literal: true

json.extract! brand, :id, :name

if brand.logo.attached?
  json.logo_url url_for(brand.logo)
else
  json.logo_url nil
end

if brand.cover.attached?
  json.cover_url url_for(brand.cover)
else
  json.cover_url nil
end
