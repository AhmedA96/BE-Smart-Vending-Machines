# frozen_string_literal: true

# == Schema Information
#
# Table name: categories
#
#  id                 :bigint           not null, primary key
#  active             :boolean          default(TRUE), not null
#  name               :string
#  position           :integer          default(0)
#  presentation       :string
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  parent_category_id :bigint
#
# Indexes
#
#  index_categories_on_parent_category_id  (parent_category_id)
#
# Foreign Keys
#
#  fk_rails_...  (parent_category_id => categories.id)
#
class Category < ApplicationRecord
  validates :name, :presentation, presence: true
end
