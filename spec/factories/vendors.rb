# frozen_string_literal: true

FactoryBot.define do
  factory :vendor do
    name { 'MyString' }
    contact_person { 'MyString' }
    phone_number { 'MyString' }
    email { 'MyString' }
    address { 'MyText' }
  end
end
