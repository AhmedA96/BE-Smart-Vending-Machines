# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_05_18_021744) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "postgis"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "brand_translations", force: :cascade do |t|
    t.string "presentation"
    t.text "description"
    t.string "locale", null: false
    t.bigint "brand_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["brand_id", "locale"], name: "index_brand_translations_on_brand_id_and_locale", unique: true
    t.index ["locale"], name: "index_brand_translations_on_locale"
  end

  create_table "brands", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.string "logo"
    t.string "background"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "categories", force: :cascade do |t|
    t.string "name"
    t.boolean "active", default: true, null: false
    t.string "presentation"
    t.integer "position", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "category_translations", force: :cascade do |t|
    t.string "presentation"
    t.text "description"
    t.string "locale", null: false
    t.bigint "category_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category_id", "locale"], name: "index_category_translations_on_category_id_and_locale", unique: true
    t.index ["locale"], name: "index_category_translations_on_locale"
  end

  create_table "line_items", force: :cascade do |t|
    t.integer "quantity", null: false
    t.decimal "price", precision: 10, scale: 2, default: "0.0"
    t.boolean "processed", default: false, null: false
    t.decimal "price_after_discount", precision: 10, scale: 2
    t.decimal "buyx_gety_discount", precision: 10, scale: 2
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "variant_id"
    t.bigint "order_id"
    t.index ["order_id"], name: "index_line_items_on_order_id"
    t.index ["variant_id"], name: "index_line_items_on_variant_id"
  end

  create_table "location_translations", force: :cascade do |t|
    t.string "name"
    t.string "locale", null: false
    t.bigint "location_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["locale"], name: "index_location_translations_on_locale"
    t.index ["location_id", "locale"], name: "index_location_translations_on_location_id_and_locale", unique: true
  end

  create_table "locations", force: :cascade do |t|
    t.string "name"
    t.string "address"
    t.string "city"
    t.string "landmark"
    t.string "state"
    t.string "zip_code"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "price_list_id"
    t.index ["price_list_id"], name: "index_locations_on_price_list_id"
  end

  create_table "machine_categories", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "machine_category_translations", force: :cascade do |t|
    t.string "presentation"
    t.text "description"
    t.string "locale", null: false
    t.bigint "machine_category_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["locale"], name: "index_machine_category_translations_on_locale"
    t.index ["machine_category_id", "locale"], name: "index_mc_translations_on_machine_category_id_and_locale", unique: true
  end

  create_table "machine_items", force: :cascade do |t|
    t.bigint "machine_id", null: false
    t.integer "stock", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "variant_id", null: false
    t.integer "line_number"
    t.index ["machine_id", "variant_id"], name: "index_machine_items_on_machine_id_and_variant_id", unique: true
    t.index ["machine_id"], name: "index_machine_items_on_machine_id"
    t.index ["variant_id"], name: "index_machine_items_on_variant_id"
  end

  create_table "machine_statuses", force: :cascade do |t|
    t.bigint "machine_id", null: false
    t.string "status"
    t.datetime "changed_at"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["machine_id"], name: "index_machine_statuses_on_machine_id"
  end

  create_table "machine_translations", force: :cascade do |t|
    t.string "name"
    t.string "locale", null: false
    t.bigint "machine_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["locale"], name: "index_machine_translations_on_locale"
    t.index ["machine_id", "locale"], name: "index_machine_translations_on_machine_id_and_locale", unique: true
  end

  create_table "machines", force: :cascade do |t|
    t.string "external_machine_id"
    t.string "name"
    t.bigint "category_id", null: false
    t.bigint "vendor_id", null: false
    t.string "status"
    t.datetime "installed_at"
    t.datetime "last_service_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.geography "coordinates", limit: {srid: 4326, type: "st_point", geographic: true}
    t.datetime "location_updated_at"
    t.bigint "location_id"
    t.integer "floor_no"
    t.bigint "supplier_id"
    t.index ["category_id"], name: "index_machines_on_category_id"
    t.index ["coordinates"], name: "index_machines_on_coordinates", using: :gist
    t.index ["external_machine_id"], name: "index_machines_on_external_machine_id", unique: true
    t.index ["location_id"], name: "index_machines_on_location_id"
    t.index ["supplier_id"], name: "index_machines_on_supplier_id"
    t.index ["vendor_id"], name: "index_machines_on_vendor_id"
  end

  create_table "oauth_access_grants", force: :cascade do |t|
    t.bigint "resource_owner_id", null: false
    t.bigint "application_id", null: false
    t.string "token", null: false
    t.integer "expires_in", null: false
    t.text "redirect_uri", null: false
    t.string "scopes", default: "", null: false
    t.datetime "created_at", null: false
    t.datetime "revoked_at"
    t.index ["application_id"], name: "index_oauth_access_grants_on_application_id"
    t.index ["resource_owner_id"], name: "index_oauth_access_grants_on_resource_owner_id"
    t.index ["token"], name: "index_oauth_access_grants_on_token", unique: true
  end

  create_table "oauth_access_tokens", force: :cascade do |t|
    t.bigint "resource_owner_id"
    t.bigint "application_id"
    t.string "token", null: false
    t.string "refresh_token"
    t.integer "expires_in"
    t.string "scopes"
    t.datetime "created_at", null: false
    t.datetime "revoked_at"
    t.string "previous_refresh_token", default: "", null: false
    t.index ["application_id"], name: "index_oauth_access_tokens_on_application_id"
    t.index ["refresh_token"], name: "index_oauth_access_tokens_on_refresh_token", unique: true
    t.index ["resource_owner_id"], name: "index_oauth_access_tokens_on_resource_owner_id"
    t.index ["token"], name: "index_oauth_access_tokens_on_token", unique: true
  end

  create_table "oauth_applications", force: :cascade do |t|
    t.string "name", null: false
    t.string "uid", null: false
    t.string "secret", null: false
    t.text "redirect_uri", null: false
    t.string "scopes", default: "", null: false
    t.boolean "confidential", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["uid"], name: "index_oauth_applications_on_uid", unique: true
  end

  create_table "orders", force: :cascade do |t|
    t.string "number", null: false
    t.decimal "total", precision: 10, scale: 2, default: "0.0"
    t.decimal "items_total", precision: 10, scale: 2, default: "0.0"
    t.decimal "total_tax", precision: 10, scale: 2, default: "0.0"
    t.decimal "total_discounts", precision: 10, scale: 2, default: "0.0"
    t.string "payment_method"
    t.string "status"
    t.string "dispense_status"
    t.jsonb "machine_response"
    t.datetime "completed_at"
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.bigint "machine_id", null: false
    t.index ["machine_id"], name: "index_orders_on_machine_id"
    t.index ["user_id"], name: "index_orders_on_user_id"
  end

  create_table "price_list_items", force: :cascade do |t|
    t.bigint "price_list_id", null: false
    t.decimal "price", precision: 10, scale: 2, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "variant_id"
    t.index ["price_list_id", "variant_id"], name: "index_price_list_items_on_price_list_id_and_variant_id", unique: true
    t.index ["price_list_id"], name: "index_price_list_items_on_price_list_id"
    t.index ["variant_id"], name: "index_price_list_items_on_variant_id"
  end

  create_table "price_lists", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "product_categories", force: :cascade do |t|
    t.bigint "product_id"
    t.bigint "category_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category_id"], name: "index_product_categories_on_category_id"
    t.index ["product_id", "category_id"], name: "index_product_categories_uniqueness", unique: true
    t.index ["product_id"], name: "index_product_categories_on_product_id"
  end

  create_table "product_translations", force: :cascade do |t|
    t.string "presentation"
    t.text "description"
    t.string "locale", null: false
    t.bigint "product_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["locale"], name: "index_product_translations_on_locale"
    t.index ["product_id", "locale"], name: "index_product_translations_on_product_id_and_locale", unique: true
  end

  create_table "products", force: :cascade do |t|
    t.string "name", null: false
    t.string "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "status"
    t.string "slug"
    t.datetime "deleted_at"
    t.float "total_rate"
    t.integer "max_orderable_quantity"
    t.integer "position", default: 1
    t.bigint "brand_id"
    t.string "presentation"
    t.index ["brand_id"], name: "index_products_on_brand_id"
    t.index ["created_at"], name: "index_products_on_created_at"
    t.index ["deleted_at"], name: "index_products_on_deleted_at"
    t.index ["name"], name: "index_products_on_name"
    t.index ["position"], name: "index_products_on_position"
  end

  create_table "roles", force: :cascade do |t|
    t.string "name"
    t.string "resource_type"
    t.bigint "resource_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name", "resource_type", "resource_id"], name: "index_roles_on_name_and_resource_type_and_resource_id"
    t.index ["resource_type", "resource_id"], name: "index_roles_on_resource"
  end

  create_table "suppliers", force: :cascade do |t|
    t.string "name", null: false
    t.string "app_id", null: false
    t.string "app_secret", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "base_url"
  end

  create_table "users", force: :cascade do |t|
    t.string "email"
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "avatar"
    t.date "date_of_birth"
    t.string "locale", default: "en"
    t.string "mobile_number"
    t.boolean "verified", default: false, null: false
    t.datetime "last_active_at"
    t.datetime "deleted_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.integer "failed_attempts", default: 0, null: false
    t.string "unlock_token"
    t.datetime "locked_at"
    t.string "name"
    t.boolean "email_notification", default: true, null: false
    t.boolean "sms_notification", default: true, null: false
    t.string "uid"
    t.string "provider"
    t.string "hashed_password"
    t.bigint "profile_id"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["locale"], name: "index_users_on_locale"
    t.index ["mobile_number"], name: "index_users_on_mobile_number", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "users_roles", primary_key: "key", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "role_id"
    t.index ["role_id"], name: "index_users_roles_on_role_id"
    t.index ["user_id", "role_id"], name: "index_unique_user_role", unique: true
  end

  create_table "variant_translations", force: :cascade do |t|
    t.string "presentation"
    t.string "locale", null: false
    t.bigint "variant_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["locale"], name: "index_variant_translations_on_locale"
    t.index ["variant_id", "locale"], name: "index_variant_translations_on_variant_id_and_locale", unique: true
    t.index ["variant_id"], name: "index_variant_translations_on_variant_id"
  end

  create_table "variants", force: :cascade do |t|
    t.string "sku", null: false
    t.string "name"
    t.integer "points"
    t.float "weight", default: 0.0
    t.boolean "is_master", default: false, null: false
    t.boolean "active", default: true
    t.integer "position", default: 1
    t.integer "product_id"
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "cost_price", precision: 10, scale: 2, default: "0.0"
    t.index ["active"], name: "index_variants_on_active"
    t.index ["created_at"], name: "index_variants_on_created_at"
    t.index ["deleted_at"], name: "index_variants_on_deleted_at"
    t.index ["position"], name: "index_variants_on_position"
    t.index ["product_id"], name: "index_variants_on_product_id"
    t.index ["sku"], name: "index_variants_on_sku", unique: true
  end

  create_table "vendors", force: :cascade do |t|
    t.string "name"
    t.string "contact_person"
    t.string "phone_number"
    t.string "email"
    t.text "address"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "brand_translations", "brands"
  add_foreign_key "category_translations", "categories"
  add_foreign_key "line_items", "orders"
  add_foreign_key "line_items", "variants"
  add_foreign_key "location_translations", "locations"
  add_foreign_key "locations", "price_lists"
  add_foreign_key "machine_category_translations", "machine_categories"
  add_foreign_key "machine_items", "machines"
  add_foreign_key "machine_items", "variants"
  add_foreign_key "machine_statuses", "machines"
  add_foreign_key "machine_translations", "machines"
  add_foreign_key "machines", "locations"
  add_foreign_key "machines", "suppliers"
  add_foreign_key "machines", "vendors"
  add_foreign_key "oauth_access_grants", "oauth_applications", column: "application_id"
  add_foreign_key "orders", "machines"
  add_foreign_key "orders", "users"
  add_foreign_key "price_list_items", "price_lists"
  add_foreign_key "price_list_items", "variants"
  add_foreign_key "product_categories", "categories"
  add_foreign_key "product_categories", "products"
  add_foreign_key "product_translations", "products"
  add_foreign_key "products", "brands"
  add_foreign_key "variant_translations", "variants"
end
