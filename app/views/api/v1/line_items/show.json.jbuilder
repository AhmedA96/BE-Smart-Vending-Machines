# frozen_string_literal: true

json.line_items do
  json.partial! 'line_item', line_item: @line_item, price_list: @line_item.price_list
end
