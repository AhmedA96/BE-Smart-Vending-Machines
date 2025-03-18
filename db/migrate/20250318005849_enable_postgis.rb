# frozen_string_literal: true

class EnablePostgis < ActiveRecord::Migration[8.0]
  def change
    enable_extension 'postgis'
    enable_extension 'postgis_topology'
  end
end
