# frozen_string_literal: true

# == Schema Information
#
# Table name: machine_categories
#
#  id          :bigint           not null, primary key
#  description :text
#  name        :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
class MachineCategory < ApplicationRecord
  has_many :vending_machines, foreign_key: 'category_id', inverse_of: :category
end
