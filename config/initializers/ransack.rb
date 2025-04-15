# frozen_string_literal: true

Ransack.configure do |config|
  %w[
    contained_within
    contained_within_or_equals
    contains
    contains_or_equals
    overlap
  ].each do |p|
    config.add_predicate p, arel_predicate: p, wants_array: true
  end
end
