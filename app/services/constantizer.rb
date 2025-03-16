# frozen_string_literal: true

class Constantizer
  def self.safe_constantize(class_name)
    model = Object.const_get(class_name) if Object.const_defined?(class_name)
    model.is_a?(Class) || model.is_a?(Module) ? model : nil
  rescue NameError, ArgumentError
    nil
  end
end
