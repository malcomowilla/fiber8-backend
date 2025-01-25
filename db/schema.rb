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

ActiveRecord::Schema[7.1].define(version: 2025_01_23_161432) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "accounts", force: :cascade do |t|
    t.string "subdomain"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "domain"
  end

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

  create_table "admin_web_authn_credentials", force: :cascade do |t|
    t.string "webauthn_id"
    t.string "public_key"
    t.integer "sign_count"
    t.integer "user_id"
    t.integer "account_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "client_mac_adresses", force: :cascade do |t|
    t.string "macadress"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "company_settings", force: :cascade do |t|
    t.string "company_name"
    t.string "email_info"
    t.string "contact_info"
    t.string "agent_email"
    t.string "customer_support_phone_number"
    t.string "customer_support_email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "account_id"
    t.string "logo"
  end

  create_table "hotspot_packages", force: :cascade do |t|
    t.string "name"
    t.string "price"
    t.string "download_limit"
    t.string "upload_limit"
    t.integer "account_id"
    t.string "tx_rate_limit"
    t.string "rx_rate_limit"
    t.string "validity_period_units"
    t.string "download_burst_limit"
    t.integer "validity"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "profile_id"
    t.string "limitation_id"
    t.string "profile_limitation_id"
    t.string "upload_burst_limit"
    t.string "user_profile_id"
  end

  create_table "nas_routers", force: :cascade do |t|
    t.string "name"
    t.string "ip_address"
    t.string "username"
    t.string "password"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "account_id"
  end

  create_table "p_poe_packages", id: false, force: :cascade do |t|
    t.string "name"
    t.string "price"
    t.string "download_limit"
    t.string "upload_limit"
    t.string "tx_rate_limit"
    t.string "rx_rate_limit"
    t.string "validity_period_units"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "account_id"
    t.string "download_burst_limit"
    t.string "upload_burst_limit"
    t.string "mikrotik_id"
    t.integer "id"
    t.integer "validity"
  end

  create_table "packages", force: :cascade do |t|
    t.string "name"
    t.integer "price"
    t.string "download_limit"
    t.string "upload_limit"
    t.integer "account_id"
    t.string "tx_rate_limit"
    t.string "rx_rate_limit"
    t.string "validity_period_units"
    t.string "download_burst_limit"
    t.string "upload_burst_limit"
    t.integer "validity"
    t.string "mikrotik_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "limitation_id"
    t.string "profile_limitation_id"
    t.string "router_name"
  end

  create_table "prefix_and_digits", force: :cascade do |t|
    t.string "prefix"
    t.integer "minimum_digits"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "account_id"
    t.integer "user_id"
  end

  create_table "router_settings", force: :cascade do |t|
    t.string "router_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "account_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.string "welcome_message"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "subscribers", force: :cascade do |t|
    t.string "name"
    t.string "ppoe_username"
    t.string "ppoe_password"
    t.string "email"
    t.string "ppoe_package"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "date_registered"
    t.datetime "valid_until"
    t.integer "account_id"
    t.string "ref_no"
    t.serial "sequence_number"
    t.string "package_name"
    t.string "installation_fee"
    t.string "subscriber_discount"
    t.string "second_phone_number"
    t.string "router_name"
    t.string "mikrotik_user_id"
  end

  create_table "subscriptions", force: :cascade do |t|
    t.string "name"
    t.string "phone"
    t.string "package"
    t.string "status"
    t.datetime "last_subscribed"
    t.datetime "expiry"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "account_id"
  end

  create_table "system_admin_sms", force: :cascade do |t|
    t.string "user"
    t.string "message"
    t.string "status"
    t.datetime "date"
    t.string "system_user"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "system_admins", force: :cascade do |t|
    t.string "user_name"
    t.string "password_digest"
    t.string "email"
    t.string "verification_token"
    t.boolean "email_verified", default: false
    t.string "role"
    t.string "fcm_token"
    t.string "webauthn_id"
    t.jsonb "webauthn_authenticator_attachment"
    t.boolean "login_with_passkey", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "phone_number_verified"
    t.string "phone_number"
    t.boolean "system_admin_phone_number_verified", default: false
    t.string "system_admin_phone_number"
    t.string "otp"
  end

  create_table "users", force: :cascade do |t|
    t.string "email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "password_digest"
    t.string "username"
    t.integer "account_id"
    t.string "phone_number"
    t.string "webauthn_id"
    t.jsonb "webauthn_authenticator_attachment"
    t.integer "role", default: 0
  end

  create_table "zones", force: :cascade do |t|
    t.string "name"
    t.string "zone_code"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "account_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
end
