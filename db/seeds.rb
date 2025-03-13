# frozen_string_literal: true

# Clear existing data to avoid duplication when running seeds multiple times
Rails.logger.debug 'Cleaning database...'

MachineStatus.destroy_all
VendingMachine.destroy_all
Vendor.destroy_all
MachineCategory.destroy_all
User.destroy_all
Role.destroy_all

Rails.logger.debug 'Database cleaned!'

# ---------------------------- #
# Machine Categories
# ---------------------------- #
Rails.logger.debug 'Creating Machine Categories...'

categories = [
  { name: 'Snacks', description: 'Snack dispensing machines.' },
  { name: 'Beverages', description: 'Hot and cold drink vending machines.' },
  { name: 'Electronics', description: 'Small electronics vending machines.' }
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
# Vending Machines
# ---------------------------- #
Rails.logger.debug 'Creating Vending Machines...'

vending_machines = [
  {
    manufacturer_id: 'SNACK-001',
    name: 'Snack Machine Alpha',
    category: machine_categories[0],
    vendor: vendor_records[1],
    location_name: 'Downtown Mall',
    latitude: 30.0444,
    longitude: 31.2357,
    status: 'active',
    installed_at: 6.months.ago,
    last_service_date: 1.month.ago
  },
  {
    manufacturer_id: 'BEV-101',
    name: 'Drink Machine Beta',
    category: machine_categories[1],
    vendor: vendor_records[0],
    location_name: 'Tech Park',
    latitude: 30.0333,
    longitude: 31.2333,
    status: 'maintenance',
    installed_at: 1.year.ago,
    last_service_date: 2.months.ago
  }
]

vending_machine_records = VendingMachine.create!(vending_machines)

Rails.logger.debug { "Created #{vending_machine_records.count} Vending Machines." }

# ---------------------------- #
# Machine Statuses
# ---------------------------- #
Rails.logger.debug 'Creating Machine Statuses...'

machine_statuses = [
  {
    vending_machine: vending_machine_records[0],
    status: 'active',
    changed_at: 1.day.ago,
    notes: 'Checked and fully operational'
  },
  {
    vending_machine: vending_machine_records[1],
    status: 'maintenance',
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
Rails.logger.debug { "Machine Categories: #{MachineCategory.count}" }
Rails.logger.debug { "Vendors: #{Vendor.count}" }
Rails.logger.debug { "Vending Machines: #{VendingMachine.count}" }
Rails.logger.debug { "Machine Statuses: #{MachineStatus.count}" }
Rails.logger.debug { "Roles: #{Role.count}" }
Rails.logger.debug { "Users: #{User.count}" }
