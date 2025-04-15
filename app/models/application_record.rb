# frozen_string_literal: true

class ApplicationRecord < ActiveRecord::Base
  include RansackScope

  primary_abstract_class

  def self.ransackable_attributes(_auth_object = nil)
    authorizable_ransackable_attributes
  end

  def self.ransackable_associations(_auth_object = nil)
    authorizable_ransackable_associations
  end
end
