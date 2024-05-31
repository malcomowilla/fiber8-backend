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

ActiveRecord::Schema[7.1].define(version: 2024_05_21_163833) do
  create_table "accounts", force: :cascade do |t|
    t.string "subdomain"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "domain"
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

  create_table "p_poe_packages", force: :cascade do |t|
    t.string "name"
    t.string "price"
    t.string "download_limit"
    t.string "upload_limit"
    t.integer "account_id"
    t.string "tx_rate_limit"
    t.string "rx_rate_limit"
    t.string "validity_period_units"
    t.string "download_burst_limit"
    t.string "upload_burst_limit"
    t.string "mikrotik_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "validiity"
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
    t.integer "sequence_number"
    t.string "package_name"
    t.string "installation_fee"
    t.string "subscriber_discount"
    t.string "second_phone_number"
    t.string "router_name"
    t.string "phone_number"
    t.string "mikrotik_user_id"
    t.index ["sequence_number"], name: "index_subscribers_on_sequence_number"
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

  create_table "users", force: :cascade do |t|
    t.string "email"
    t.string "password_digest"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "username"
    t.integer "account_id"
  end

  create_table "zones", force: :cascade do |t|
    t.string "name"
    t.string "zone_code"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "account_id"
  end

end
