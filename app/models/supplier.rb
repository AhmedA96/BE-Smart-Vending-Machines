# frozen_string_literal: true

# == Schema Information
#
# Table name: suppliers
#
#  id            :bigint           not null, primary key
#  app_secret    :string           not null
#  base_url      :string
#  name          :string           not null
#  supplier_type :string           default(NULL)
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  app_id        :string           not null
#
# Indexes
#
#  index_suppliers_on_supplier_type  (supplier_type)
#
class Supplier < ApplicationRecord
  validates :name, :app_id, :app_secret, presence: true
  validates :base_url, presence: true

  has_many :machines, dependent: :destroy
  has_many :orders, through: :machines
  has_many :machine_items, through: :machines
  has_one_attached :image

  # Define the enum for supplier types
  enum :supplier_type, {
    vendlife: 'vendlife',
    reyah: 'reyah'
  }

  # Validation to ensure only supported types are used
  validates :supplier_type, inclusion: { in: supplier_types.keys }

  def api_service
    @api_service ||= Suppliers::Factory.build(self)
  end

  def supported_features
    api_service.supported_features
  rescue UnsupportedSupplierError
    {}
  end
end
