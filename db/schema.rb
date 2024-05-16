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

ActiveRecord::Schema[7.1].define(version: 2024_05_16_105016) do
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
  end

  create_table "subscribers", force: :cascade do |t|
    t.string "name"
    t.integer "phone_number"
    t.string "ppoe_username"
    t.string "ppoe_password"
    t.string "email"
    t.string "ppoe_package"
    t.date "date_registered"
    t.integer "ref_no"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
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
