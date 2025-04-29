# frozen_string_literal: true

# Clear existing data to avoid duplication when running seeds multiple times
Rails.logger.debug 'Cleaning database...'

MachineStatus.destroy_all
MachineItem.destroy_all
Machine.destroy_all
Vendor.destroy_all
MachineCategory.destroy_all
ProductCategory.destroy_all
Variant.destroy_all
Product.update_all(brand_id: nil) # rubocop:disable Rails/SkipsModelValidations
Product.destroy_all
Brand.destroy_all
Category.destroy_all
PriceList.destroy_all
Location.destroy_all

# Clear users_roles join table using delete_all to bypass model callbacks
ActiveRecord::Base.connection.execute('DELETE FROM users_roles')
User.destroy_all
Role.destroy_all

Rails.logger.debug 'Database cleaned!'

# ---------------------------- #
# Categories
# ---------------------------- #
Rails.logger.debug 'Creating Categories...'

# Create parent categories first
parent_categories = [
  { name: 'Food & Beverages', presentation: 'Food & Beverages', active: true, position: 1 },
  { name: 'Electronics', presentation: 'Electronics', active: true, position: 4 }
]

parent_records = Category.create!(parent_categories)

# Create child categories with the correct parent_category_id references
child_categories = [
  { name: 'Snacks', presentation: 'Snacks', active: true, position: 2, parent_category_id: parent_records[0].id },
  { name: 'Drinks', presentation: 'Drinks', active: true, position: 3, parent_category_id: parent_records[0].id }
]

child_records = Category.create!(child_categories)

category_records = parent_records + child_records

Rails.logger.debug { "Created #{category_records.count} Categories." }

# ---------------------------- #
# Brands
# ---------------------------- #
Rails.logger.debug 'Creating Brands...'

brands = [
  { name: 'Coca-Cola', description: 'The world\'s leading beverage company' },
  { name: 'Frito-Lay', description: 'A subsidiary of PepsiCo that manufactures snack foods' }
]

brand_records = Brand.create!(brands)
Rails.logger.debug { "Created #{brand_records.count} Brands with logos." }

# ---------------------------- #
# Products
# ---------------------------- #
Rails.logger.debug 'Creating Products...'

products = [
  {
    name: 'Cola Classic',
    description: 'Refreshing cola drink',
    status: 'Active',
    slug: 'cola-classic',
    total_rate: 4.5,
    max_orderable_quantity: 5,
    position: 1,
    brand: brand_records[0]
  },
  {
    name: 'Potato Chips',
    description: 'Crispy salted chips',
    status: 'Active',
    slug: 'potato-chips',
    total_rate: 4.0,
    max_orderable_quantity: 3,
    position: 2,
    brand: brand_records[1]
  }
]

product_records = Product.create!(products)

# Attach images to products
product_records[0].images.attach(io: Rails.root.join('app/assets/images/products/cola.svg').open,
                                 filename: 'cola.svg', content_type: 'image/svg+xml')
product_records[1].images.attach(io: Rails.root.join('app/assets/images/products/chips.svg').open,
                                 filename: 'chips.svg', content_type: 'image/svg+xml')

Rails.logger.debug { "Created #{product_records.count} Products with images." }

# ---------------------------- #
# Product Categories
# ---------------------------- #
Rails.logger.debug 'Creating Product Categories...'

product_categories = [
  { product: product_records[0], category: category_records[2] },
  { product: product_records[1], category: category_records[1] }
]

ProductCategory.create!(product_categories)

Rails.logger.debug { "Created #{product_categories.count} Product Categories." }

# ---------------------------- #
# Variants
# ---------------------------- #
Rails.logger.debug 'Creating Variants...'

# Generate unique SKUs by adding timestamp
time_suffix = Time.current.to_i

variants = [
  {
    name: 'Cola Classic 330ml',
    sku: "COLA-330-#{time_suffix}",
    is_master: true,
    points: 10,
    weight: 0.33,
    product: product_records[0],
    position: 1
  },
  {
    name: 'Cola Classic 500ml',
    sku: "COLA-500-#{time_suffix}",
    is_master: false,
    points: 15,
    weight: 0.5,
    product: product_records[0],
    position: 2
  },
  {
    name: 'Regular Chips 100g',
    sku: "CHIPS-100-#{time_suffix}",
    is_master: true,
    points: 8,
    weight: 0.1,
    product: product_records[1],
    position: 1
  }
]

variant_records = Variant.create!(variants)

Rails.logger.debug { "Created #{variant_records.count} Variants." }

# ---------------------------- #
# Price Lists
# ---------------------------- #
Rails.logger.debug 'Creating Price Lists...'

price_lists = [
  { name: 'Standard Prices' },
  { name: 'Premium Locations' }
]

price_list_records = PriceList.create!(price_lists)

price_list_items = [
  { price_list: price_list_records[0], variant: variant_records[0], price: 2.50 },
  { price_list: price_list_records[0], variant: variant_records[2], price: 1.50 },
  { price_list: price_list_records[1], variant: variant_records[1], price: 3.00 },
  { price_list: price_list_records[1], variant: variant_records[2], price: 2.00 }
]

PriceListItem.create!(price_list_items)

Rails.logger.debug { "Created #{price_list_records.count} Price Lists with #{price_list_items.count} items." }

# ---------------------------- #
# Locations
# ---------------------------- #
Rails.logger.debug 'Creating Locations...'

locations = [
  {
    name: 'Downtown Mall',
    address: '123 Mall Street',
    city: 'Cairo',
    state: 'Cairo Governorate',
    zip_code: '11511',
    landmark: 'Near Central Square',
    price_list: price_list_records[1]
  },
  {
    name: 'Tech Park',
    address: '456 Innovation Avenue',
    city: 'Giza',
    state: 'Giza Governorate',
    zip_code: '12511',
    landmark: 'Next to Science Museum',
    price_list: price_list_records[0]
  },
  {
    name: 'Shopping Center',
    address: '789 Retail Boulevard',
    city: 'Alexandria',
    state: 'Alexandria Governorate',
    zip_code: '21511',
    landmark: 'Opposite Central Park',
    price_list: price_list_records[1]
  },
  {
    name: 'University Campus',
    address: '321 Education Road',
    city: 'Cairo',
    state: 'Cairo Governorate',
    zip_code: '11522',
    landmark: 'Main Campus Gate',
    price_list: price_list_records[0]
  }
]

location_records = Location.create!(locations)

Rails.logger.debug { "Created #{location_records.count} Locations." }

# ---------------------------- #
# Machine Categories
# ---------------------------- #
Rails.logger.debug 'Creating Machine Categories...'

categories = [
  { name: 'Snacks', description: 'Snack dispensing machines.' },
  { name: 'Beverages', description: 'Hot and cold drink machines.' },
  { name: 'Electronics', description: 'Small electronics machines.' }
]

machine_categories = MachineCategory.create!(categories)

Rails.logger.debug { "Created #{machine_categories.count} Machine Categories." }

# ---------------------------- #
# Vendors
# ---------------------------- #
Rails.logger.debug 'Creating Vendors...'

vendors = [
  { name: 'Cool Drinks Co.', contact_person: 'Alice Johnson', phone_number: '1234567890',
    email: 'contact@cooldrinks.com', address: '123 Cool St, City' },
  { name: 'Snack House', contact_person: 'Bob Smith', phone_number: '0987654321', email: 'sales@snackhouse.com',
    address: '456 Snack Ave, City' }
]

vendor_records = Vendor.create!(vendors)

Rails.logger.debug { "Created #{vendor_records.count} Vendors." }

# ---------------------------- #
# Machines
# ---------------------------- #
Rails.logger.debug 'Creating Machines...'

machines = [
  {
    external_machine_id: 'SNACK-001',
    name: 'Snack Machine Alpha',
    category: machine_categories[0],
    vendor: vendor_records[1],
    location: location_records[0],
    price_list: location_records[0].price_list,
    status: 'Active',
    coordinates: 'POINT(31.2357 30.0444)',
    installed_at: 6.months.ago,
    last_service_date: 1.month.ago
  },
  {
    external_machine_id: 'BEV-101',
    name: 'Drink Machine Beta',
    category: machine_categories[1],
    vendor: vendor_records[0],
    location: location_records[1],
    price_list: location_records[1].price_list,
    status: 'Maintenance',
    coordinates: 'POINT(31.3074 30.0566)',
    installed_at: 1.year.ago,
    last_service_date: 2.months.ago
  },
  {
    external_machine_id: 'ELEC-201',
    name: 'Electronics Vendor Gamma',
    category: machine_categories[2],
    vendor: vendor_records[0],
    location: location_records[2],
    price_list: location_records[2].price_list,
    status: 'Active',
    coordinates: 'POINT(31.3074 30.0566)',
    installed_at: 3.months.ago,
    last_service_date: 1.week.ago
  },
  {
    external_machine_id: 'SNACK-002',
    name: 'Snack Machine Delta',
    category: machine_categories[0],
    vendor: vendor_records[1],
    location: location_records[3],
    price_list: location_records[3].price_list,
    status: 'Inactive',
    coordinates: 'POINT(31.2646 30.0355)',
    installed_at: 8.months.ago,
    last_service_date: 3.months.ago
  }
]

machine_records = Machine.create!(machines)

Rails.logger.debug { "Created #{machine_records.count} Machines." }

# ---------------------------- #
# Machine Items
# ---------------------------- #
Rails.logger.debug 'Creating Machine Items...'

machine_items = [
  {
    machine: machine_records[0],
    variant: variant_records[0],
    stock: 20
  },
  {
    machine: machine_records[0],
    variant: variant_records[2],
    stock: 15
  },
  {
    machine: machine_records[1],
    variant: variant_records[1],
    stock: 25
  }
]

machine_item_records = MachineItem.create!(machine_items)

Rails.logger.debug { "Created #{machine_item_records.count} Machine Items." }

# ---------------------------- #
# Machine Statuses
# ---------------------------- #
Rails.logger.debug 'Creating Machine Statuses...'

machine_statuses = [
  {
    machine: machine_records[0],
    status: 'Active',
    changed_at: 1.day.ago,
    notes: 'Checked and fully operational'
  },
  {
    machine: machine_records[1],
    status: 'Maintenance',
    changed_at: 2.days.ago,
    notes: 'Reported minor issues with coin acceptor'
  }
]

MachineStatus.create!(machine_statuses)

Rails.logger.debug { "Created #{machine_statuses.count} Machine Status records." }

# ---------------------------- #
# Roles
# ---------------------------- #
Rails.logger.debug 'Creating Roles...'

roles = [
  { name: 'admin' },
  { name: 'technician' },
  { name: 'vendor_manager' }
]

role_records = Role.create!(roles)

Rails.logger.debug { "Created #{role_records.count} Roles." }

# ---------------------------- #
# Users
# ---------------------------- #
Rails.logger.debug 'Creating Users...'

users = [
  {
    email: 'admin@example.com',
    password: 'Password!234',
    name: 'Admin User',
    mobile_number: '+201000000001',
    verified: true,
    role_ids: [role_records[0].id]
  },
  {
    email: 'tech@example.com',
    password: 'Password!234',
    name: 'Tech User',
    mobile_number: '+201000000002',
    verified: true,
    role_ids: [role_records[1].id]
  },
  {
    email: 'vendor@example.com',
    password: 'Password!234',
    name: 'Vendor Manager',
    mobile_number: '+201000000003',
    verified: true,
    role_ids: [role_records[2].id]
  }
]

user_records = users.map do |user_data|
  user = User.create!(
    email: user_data[:email],
    password: user_data[:password],
    name: user_data[:name],
    mobile_number: user_data[:mobile_number],
    verified: user_data[:verified]
  )
  user.add_role(Role.find(user_data[:role_ids].first).name) # Assuming rolify is used
  user
end

Rails.logger.debug { "Created #{user_records.count} Users." }

# ---------------------------- #
# Summary
# ---------------------------- #
Rails.logger.debug '✅ Seeding completed successfully!'
Rails.logger.debug { "Categories: #{Category.count}" }
Rails.logger.debug { "Products: #{Product.count}" }
Rails.logger.debug { "Variants: #{Variant.count}" }
Rails.logger.debug { "Price Lists: #{PriceList.count}" }
Rails.logger.debug { "Locations: #{Location.count}" }
Rails.logger.debug { "Machine Categories: #{MachineCategory.count}" }
Rails.logger.debug { "Vendors: #{Vendor.count}" }
Rails.logger.debug { "Machines: #{Machine.count}" }
Rails.logger.debug { "Machine Items: #{MachineItem.count}" }
Rails.logger.debug { "Machine Statuses: #{MachineStatus.count}" }
Rails.logger.debug { "Roles: #{Role.count}" }
Rails.logger.debug { "Users: #{User.count}" }
