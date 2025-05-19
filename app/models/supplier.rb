# frozen_string_literal: true

# == Schema Information
#
# Table name: suppliers
#
#  id         :bigint           not null, primary key
#  app_secret :string           not null
#  base_url   :string
#  name       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  app_id     :string           not null
#
class Supplier < ApplicationRecord
  validates :name, :app_id, :app_secret, presence: true

  has_many :machines, dependent: :nullify
end
