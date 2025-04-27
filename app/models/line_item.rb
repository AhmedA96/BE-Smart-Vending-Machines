# == Schema Information
#
# Table name: line_items
#
#  id                   :bigint           not null, primary key
#  buyx_gety_discount   :decimal(10, 2)
#  price                :decimal(10, 2)   default(0.0)
#  price_after_discount :decimal(10, 2)
#  processed            :boolean          default(FALSE), not null
#  quantity             :integer          not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#
class LineItem < ApplicationRecord
end
