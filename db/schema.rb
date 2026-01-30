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

ActiveRecord::Schema[7.2].define(version: 2026_01_30_120254) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "accounts", force: :cascade do |t|
    t.string "subdomain"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "domain"
    t.datetime "last_invoiced_at"
    t.index ["subdomain"], name: "index_accounts_on_subdomain", unique: true
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

  create_table "activty_logs", force: :cascade do |t|
    t.string "action"
    t.string "subject"
    t.string "description"
    t.string "user"
    t.datetime "date"
    t.integer "account_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.string "ip"
  end

  create_table "ad_settings", force: :cascade do |t|
    t.boolean "enabled"
    t.boolean "to_right"
    t.boolean "to_left"
    t.boolean "to_top"
    t.integer "account_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "admin_settings", force: :cascade do |t|
    t.boolean "enable_2fa_for_admin_sms"
    t.boolean "enable_2fa_for_admin_email"
    t.boolean "send_password_via_sms"
    t.boolean "send_password_via_email"
    t.boolean "check_inactive_days"
    t.boolean "check_inactive_hrs"
    t.boolean "check_inactive_minutes"
    t.boolean "enable_2fa_for_admin_passkeys"
    t.integer "account_id"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "check_is_inactive", default: false
    t.string "checkinactiveminutes"
    t.string "checkinactivehrs"
    t.string "checkinactivedays"
    t.boolean "enable_2fa_google_auth", default: false
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

  create_table "ads", force: :cascade do |t|
    t.string "title"
    t.string "description"
    t.string "business_name"
    t.string "business_type"
    t.string "offer_text"
    t.string "discount"
    t.string "cat_text"
    t.string "background_color"
    t.string "text_color"
    t.string "image"
    t.string "imagePreview"
    t.string "target_url"
    t.boolean "is_active"
    t.integer "account_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "image_preview"
    t.string "phone"
    t.string "email"
    t.string "website"
    t.string "status"
  end

  create_table "analytics_events", force: :cascade do |t|
    t.string "event_type"
    t.string "details"
    t.datetime "timestamp"
    t.integer "account_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "button_name"
  end

  create_table "calendar_events", force: :cascade do |t|
    t.string "event_title"
    t.datetime "start_date_time"
    t.datetime "end_date_time"
    t.string "title"
    t.datetime "start"
    t.datetime "end"
    t.integer "account_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "client"
    t.string "assigned_to"
    t.string "task_type"
    t.string "status"
    t.string "description"
  end

  create_table "calendar_settings", force: :cascade do |t|
    t.string "start_in_hours"
    t.string "start_in_minutes"
    t.integer "account_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "cdr", id: false, force: :cascade do |t|
    t.datetime "calldate", precision: nil, null: false
    t.string "clid", limit: 80
    t.string "src", limit: 80
    t.string "dst", limit: 80
    t.string "dcontext", limit: 80
    t.string "channel", limit: 80
    t.string "dstchannel", limit: 80
    t.string "lastapp", limit: 80
    t.string "lastdata", limit: 80
    t.integer "duration"
    t.integer "billsec"
    t.string "disposition", limit: 45
    t.integer "amaflags"
    t.string "accountcode", limit: 20
    t.string "uniqueid", limit: 150
    t.string "userfield", limit: 255
    t.string "peeraccount", limit: 20
    t.string "linkedid", limit: 150
    t.integer "account_id"
    t.string "dialstatus", limit: 20
  end

  create_table "change_logs", force: :cascade do |t|
    t.string "version"
    t.text "system_changes", default: [], array: true
    t.string "change_title"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "client_leads", force: :cascade do |t|
    t.string "name"
    t.string "email"
    t.string "company_name"
    t.string "phone_number"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "account_id"
    t.string "location"
  end

  create_table "client_mac_adresses", force: :cascade do |t|
    t.string "macadress"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "company_financial_records", force: :cascade do |t|
    t.string "category"
    t.boolean "is_intercompany"
    t.string "amount"
    t.string "description"
    t.string "transaction_type"
    t.string "company"
    t.datetime "date"
    t.string "counterparty"
    t.integer "account_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "reference"
  end

  create_table "company_ids", force: :cascade do |t|
    t.string "company_id"
    t.integer "account_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "company_leads", force: :cascade do |t|
    t.string "name"
    t.string "company_name"
    t.string "email"
    t.string "message"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "phone_number"
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

  create_table "customer_portals", force: :cascade do |t|
    t.string "username"
    t.string "password"
    t.integer "account_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "dial_mpesa_settings", force: :cascade do |t|
    t.integer "account_id"
    t.string "account_type"
    t.string "short_code"
    t.string "consumer_key"
    t.string "consumer_secret"
    t.string "passkey"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "dial_up_mpesa_settings", force: :cascade do |t|
    t.string "account_type"
    t.string "short_code"
    t.string "consumer_key"
    t.string "consumer_secret"
    t.string "passkey"
    t.integer "account_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "drawings", force: :cascade do |t|
    t.string "drawing_type"
    t.json "position"
    t.json "path"
    t.json "paths"
    t.json "center"
    t.json "bounds"
    t.integer "account_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "title"
  end

  create_table "email_settings", force: :cascade do |t|
    t.string "smtp_host"
    t.string "smtp_username"
    t.string "sender_email"
    t.string "smtp_password"
    t.string "api_key"
    t.string "domain"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "account_id"
    t.string "smtp_port"
  end

  create_table "equipment", force: :cascade do |t|
    t.string "user"
    t.string "name"
    t.string "model"
    t.string "serial_number"
    t.string "price"
    t.string "amount_paid"
    t.string "account_number"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "account_id"
    t.string "device_type"
    t.string "name_of_customer"
  end

  create_table "general_settings", force: :cascade do |t|
    t.string "title"
    t.string "timezone"
    t.string "allowed_ips", default: [], array: true
    t.integer "account_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "google_maps", force: :cascade do |t|
    t.string "api_key"
    t.integer "account_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "hotspot_customizations", force: :cascade do |t|
    t.boolean "customize_template_and_package_per_location"
    t.integer "account_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "enable_autologin"
  end

  create_table "hotspot_mpesa_revenues", force: :cascade do |t|
    t.string "voucher"
    t.string "payment_method"
    t.string "reference"
    t.string "time_paid"
    t.integer "account_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "amount"
  end

  create_table "hotspot_mpesa_settings", force: :cascade do |t|
    t.string "account_type"
    t.string "short_code"
    t.string "consumer_key"
    t.string "consumer_secret"
    t.string "passkey"
    t.integer "account_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "api_initiator_password"
    t.string "api_initiator_username"
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
    t.datetime "valid_from"
    t.datetime "valid_until"
    t.string "weekdays", default: [], array: true
    t.string "shared_users", default: "1"
    t.string "location"
  end

  create_table "hotspot_plans", force: :cascade do |t|
    t.string "name", default: "Free Trial"
    t.string "hotspot_subscribers", default: "unlimited"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "account_id"
    t.string "billing_cycle"
    t.string "status", default: "active"
    t.boolean "condition"
    t.datetime "expiry"
    t.string "price", default: "0"
    t.integer "expiry_days", default: 3
    t.datetime "last_invoiced_at"
    t.string "plan_name"
    t.string "company_name"
  end

  create_table "hotspot_settings", force: :cascade do |t|
    t.string "phone_number"
    t.string "hotspot_name"
    t.string "hotspot_info"
    t.string "hotspot_banner"
    t.integer "account_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "email"
    t.string "voucher_type", default: "Mixed"
  end

  create_table "hotspot_subscriptions", force: :cascade do |t|
    t.string "voucher"
    t.string "ip_address"
    t.string "start_time"
    t.string "up_time"
    t.string "download"
    t.string "upload"
    t.integer "account_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "hotspot_templates", force: :cascade do |t|
    t.string "name"
    t.integer "account_id"
    t.string "preview_image"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "sleekspot", default: false
    t.boolean "attractive", default: false
    t.boolean "clean", default: false
    t.boolean "default", default: false
    t.boolean "flat", default: false
    t.boolean "minimal", default: false
    t.boolean "simple", default: false
    t.boolean "default_template", default: false
    t.boolean "pepea"
    t.boolean "premium"
    t.string "location"
  end

  create_table "hotspot_vouchers", force: :cascade do |t|
    t.string "voucher"
    t.string "status"
    t.datetime "expiration"
    t.string "speed_limit"
    t.string "phone"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "account_id"
    t.string "package"
    t.string "user_manager_user_id"
    t.string "user_profile_id"
    t.string "shared_users"
    t.datetime "sms_sent_at"
    t.datetime "sms_sent_at_voucher"
    t.datetime "last_logged_in"
    t.string "mac"
    t.string "ip"
  end

  create_table "invoices", force: :cascade do |t|
    t.string "invoice_number"
    t.datetime "invoice_date"
    t.datetime "due_date"
    t.string "total"
    t.string "status"
    t.integer "account_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "invoice_desciption"
    t.string "plan_name"
    t.datetime "last_invoiced_at"
  end

  create_table "ip_networks", force: :cascade do |t|
    t.string "network"
    t.string "title"
    t.string "ip_adress"
    t.string "subnet_mask"
    t.integer "account_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "total_ip_addresses"
    t.string "net_mask"
    t.string "client_host_range"
    t.string "nas"
  end

  create_table "ip_pools", force: :cascade do |t|
    t.string "ip_range"
    t.string "pool_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "start_ip"
    t.string "end_ip"
    t.integer "account_id"
    t.string "description"
    t.string "ip_pool_id_mikrotik"
    t.string "location"
    t.string "nas_router"
  end

  create_table "isp_subscriptions", force: :cascade do |t|
    t.integer "account_id"
    t.datetime "next_billing_date"
    t.string "payment_status"
    t.string "currency", default: "KES"
    t.string "plan_name"
    t.string "features", default: [], array: true
    t.string "renewal_period", default: "monthly"
    t.datetime "last_payment_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "license_settings", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "phone_number"
    t.integer "account_id"
    t.boolean "phone_notification"
    t.integer "expiry_warning_days"
  end

  create_table "nas", force: :cascade do |t|
    t.string "name"
    t.string "shortname"
    t.string "ipaddr"
    t.string "secret"
    t.string "nas_type"
    t.integer "ports"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "account_id"
  end

  create_table "nas_routers", force: :cascade do |t|
    t.string "name"
    t.string "ip_address"
    t.string "username"
    t.string "password"
    t.integer "account_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "location"
    t.string "last_status"
    t.datetime "last_status_changed_at"
    t.datetime "last_notification_sent_at"
  end

  create_table "nas_settings", force: :cascade do |t|
    t.boolean "notification_when_unreachable"
    t.string "notification_phone_number"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "account_id"
    t.integer "unreachable_duration_minutes"
  end

  create_table "nodes", force: :cascade do |t|
    t.string "name"
    t.string "latitude"
    t.string "longitude"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "country"
    t.integer "account_id"
  end

  create_table "onus", force: :cascade do |t|
    t.string "serial_number"
    t.string "oui"
    t.string "product_class"
    t.string "manufacturer"
    t.string "onu_id"
    t.string "status"
    t.string "last_inform"
    t.integer "account_id"
    t.string "last_boot"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "ssid1"
    t.string "ssid2"
    t.string "wan_ip"
    t.string "mac_adress"
    t.string "software_version"
    t.string "hardware_version"
    t.string "uptime"
    t.string "cpu_used"
    t.string "ram_used"
    t.string "dhcp_name"
    t.string "dhcp_addressing_type"
    t.string "dhcp_connection_status"
    t.string "dhcp_uptime"
    t.string "dhcp_ip"
    t.string "dhcp_subnet_mask"
    t.string "dhcp_gateway"
    t.string "dhcp_dns_servers"
    t.string "dhcp_last_connection_error"
    t.string "dhcp_max_mtu_size"
    t.string "dhcp_nat_enabled"
    t.string "dhcp_vlan_id"
    t.string "dhcp_mac_address"
    t.string "wifi_password1"
    t.string "wifi_password2"
    t.string "wlan1_status"
    t.boolean "enable1"
    t.string "rf_band1"
    t.boolean "radio_enabled1"
    t.string "total_associations1"
    t.boolean "ssid_advertisment_enabled1"
    t.string "wpa_encryption1"
    t.string "channel_width1"
    t.boolean "autochannel1"
    t.string "channel"
    t.string "country_regulatory_domain1"
    t.string "tx_power1"
    t.string "authentication_mode1"
    t.string "standard1"
    t.string "lan_ip_interface_address"
    t.string "lan_ip_interface_net_mask"
    t.boolean "dhcp_server_enable"
    t.string "dhcp_ip_pool_min_addr"
    t.string "dhcp_ip_pool_max_addr"
    t.string "dhcp_server_subnet_mask"
    t.string "dhcp_server_default_gateway"
    t.string "dhcp_server_dns_servers"
    t.string "lease_time"
    t.string "clients_domain_name"
    t.string "reserved_ip_address"
    t.string "location"
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
    t.string "ip_pool"
    t.string "ppoe_profile_id"
    t.string "package"
    t.string "wifi_package"
    t.string "daily_charge"
    t.string "burst_upload_speedburst_download_speed"
    t.string "burst_threshold_download"
    t.string "burst_threshold_upload"
    t.string "burst_time"
    t.string "burst_upload_speed"
    t.string "burst_download_speed"
    t.string "aggregation"
    t.string "subscription"
  end

  create_table "pp_poe_mpesa_revenues", force: :cascade do |t|
    t.string "payment_method"
    t.string "reference"
    t.datetime "time_paid"
    t.integer "account_id"
    t.string "account_number"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "amount"
    t.string "customer_name"
  end

  create_table "pp_poe_plans", force: :cascade do |t|
    t.string "maximum_pppoe_subscribers", default: "unlimited"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name", default: "Free Trial"
    t.datetime "expiry"
    t.integer "account_id"
    t.string "billing_cycle"
    t.string "status", default: "active"
    t.boolean "condition"
    t.string "price", default: "0"
    t.integer "expiry_days", default: 3
    t.datetime "last_invoiced_at"
    t.string "plan_name"
    t.string "company_name"
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
    t.boolean "use_radius", default: false
  end

  create_table "router_statuses", force: :cascade do |t|
    t.integer "tenant_id"
    t.string "ip"
    t.boolean "reachable"
    t.text "response"
    t.datetime "checked_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "account_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.string "welcome_message"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "sms", force: :cascade do |t|
    t.string "user"
    t.string "message"
    t.datetime "date"
    t.string "status"
    t.string "admin_user"
    t.string "system_user"
    t.integer "account_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "sms_provider_settings", force: :cascade do |t|
    t.string "sms_provider"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "account_id"
  end

  create_table "sms_settings", force: :cascade do |t|
    t.string "api_key"
    t.string "api_secret"
    t.string "sender_id"
    t.string "short_code"
    t.string "username"
    t.integer "accoun_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "sms_provider"
    t.integer "account_id"
    t.string "partnerID"
    t.datetime "sms_setting_updated_at"
  end

  create_table "sms_templates", force: :cascade do |t|
    t.string "send_voucher_template"
    t.string "voucher_template"
    t.integer "account_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "subscriber_invoices", force: :cascade do |t|
    t.string "item"
    t.datetime "due_date"
    t.datetime "invoice_date"
    t.string "invoice_number"
    t.integer "amount"
    t.string "status"
    t.string "description"
    t.string "quantity"
    t.integer "account_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "subscriber_id"
    t.integer "subscription_id"
  end

  create_table "subscriber_settings", force: :cascade do |t|
    t.string "prefix"
    t.string "minimum_digits"
    t.integer "account_id"
    t.boolean "use_autogenerated_number_as_ppoe_username", default: false
    t.boolean "notify_user_account_created", default: false
    t.boolean "send_reminder_sms_expiring_subscriptions", default: false
    t.integer "account_number_starting_value", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "use_autogenerated_number_as_ppoe_password", default: false
    t.boolean "enable_customer_portal", default: false
    t.string "installation_fee"
    t.boolean "subscriber_welcome_message"
    t.boolean "lock_account_to_mac"
    t.boolean "notify_user_payment_received", default: false
    t.boolean "invoice_created_or_paid", default: false
    t.boolean "expiration_reminder", default: false
    t.string "expiration_reminder_minutes"
    t.string "expiration_reminder_hours"
    t.string "expiration_reminder_days"
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
    t.string "phone_number"
    t.string "ppoe_secrets_id"
    t.string "last_renewed"
    t.datetime "expires"
    t.boolean "online"
    t.string "location_name"
    t.string "latitude"
    t.string "longitude"
    t.string "buildin_name"
    t.string "house_number"
    t.string "building_name"
    t.datetime "expiration"
    t.datetime "registration_date"
    t.text "location", default: [], array: true
    t.string "password_digest"
    t.string "node"
    t.string "status"
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
    t.string "price"
    t.string "ip_address"
    t.string "pppoe_username"
    t.string "pppoe_password"
    t.string "type"
    t.string "ppoe_password"
    t.string "ppoe_username"
    t.string "phone_number"
    t.string "network_name"
    t.string "validity_period_units"
    t.string "validity"
    t.integer "subscriber_id"
    t.string "service_type"
    t.string "mac_address"
    t.datetime "expiration_date"
    t.string "package_name"
    t.datetime "expiration_sms_sent_at"
    t.datetime "expiry_reminder_sent_at"
  end

  create_table "support_tickets", force: :cascade do |t|
    t.string "issue_description"
    t.string "status"
    t.string "priority"
    t.string "agent"
    t.string "ticket_number"
    t.string "customer"
    t.string "name"
    t.string "email"
    t.string "phone_number"
    t.datetime "date_created"
    t.string "ticket_category"
    t.datetime "date_closed"
    t.string "agent_review"
    t.string "agent_response"
    t.integer "account_id"
    t.datetime "date_of_creation"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.serial "sequence_number"
  end

  create_table "system_admin_email_settings", force: :cascade do |t|
    t.string "smtp_host"
    t.string "smtp_username"
    t.string "sender_email"
    t.string "smtp_password"
    t.string "api_keydomain"
    t.integer "system_admin_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "system_admin_settings", force: :cascade do |t|
    t.boolean "login_with_passkey"
    t.boolean "use_sms_authentication", default: false
    t.boolean "use_email_authentication", default: false
    t.integer "system_admin_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "system_admin_sms", force: :cascade do |t|
    t.string "user"
    t.string "message"
    t.string "status"
    t.datetime "date"
    t.string "system_user"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "sms_provider"
    t.integer "account_id"
  end

  create_table "system_admin_web_authn_credentials", force: :cascade do |t|
    t.string "webauthn_id"
    t.string "public_key"
    t.integer "sign_count"
    t.integer "system_admin_id"
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
    t.boolean "use_sms_authentication", default: false
  end

  create_table "system_metrics", force: :cascade do |t|
    t.string "cpu_usage"
    t.string "memory_total"
    t.string "memory_free"
    t.string "disk_total"
    t.string "disk_free"
    t.string "load_average"
    t.integer "account_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "memory_used"
    t.string "disk_used"
    t.string "uptime"
  end

  create_table "technicians", force: :cascade do |t|
    t.string "email"
    t.string "username"
    t.string "phone_number"
    t.string "password_digest"
    t.integer "account_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "password"
    t.datetime "last_login_at"
    t.string "status"
    t.string "first_name"
    t.string "last_name"
    t.boolean "is_email_verified"
  end

  create_table "template_locations", force: :cascade do |t|
    t.string "name"
    t.string "location"
    t.integer "account_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "template_type"
  end

  create_table "temporary_sessions", force: :cascade do |t|
    t.string "session"
    t.string "ip"
    t.integer "account_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "paid"
    t.boolean "connected", default: false
  end

  create_table "ticket_settings", force: :cascade do |t|
    t.string "prefix"
    t.string "minimum_digits"
    t.integer "account_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "user_groups", force: :cascade do |t|
    t.string "name"
    t.integer "account_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
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
    t.boolean "locked_account", default: false
    t.datetime "locked_at"
    t.boolean "can_manage_subscriber", default: false
    t.boolean "can_read_read_subscriber", default: false
    t.boolean "can_manage_ticket_settings", default: false
    t.boolean "can_read_ticket_settings", default: false
    t.boolean "can_read_ppoe_package", default: false
    t.boolean "can_manage_ppoe_package", default: false
    t.boolean "can_manage_company_setting", default: false
    t.boolean "can_read_company_setting", default: false
    t.boolean "can_manage_email_setting", default: false
    t.boolean "can_read_email_setting", default: false
    t.boolean "can_manage_hotspot_packages", default: false
    t.boolean "can_read_hotspot_packages", default: false
    t.boolean "can_manage_ip_pool", default: false
    t.boolean "can_read_ip_pool", default: false
    t.boolean "can_manage_nas_routers", default: false
    t.boolean "can_read_nas_routers", default: false
    t.boolean "can_manage_router_setting", default: false
    t.boolean "can_manage_sms", default: false
    t.boolean "can_read_sms", default: false
    t.boolean "can_manage_sms_settings", default: false
    t.boolean "can_read_sms_settings", default: false
    t.boolean "can_manage_subscriber_setting", default: false
    t.boolean "can_read_subscriber_setting", default: false
    t.boolean "can_manage_subscription", default: false
    t.boolean "can_read_subscription", default: false
    t.boolean "can_read_support_tickets", default: false
    t.boolean "can_manage_users", default: false
    t.boolean "can_read_users", default: false
    t.boolean "can_manage_zones", default: false
    t.boolean "can_read_zones", default: false
    t.datetime "date_registered"
    t.boolean "send_password_via_sms", default: false
    t.boolean "send_password_via_email", default: false
    t.boolean "can_read_router_setting", default: false
    t.boolean "can_manage_user_setting", default: false
    t.boolean "can_read_user_setting", default: false
    t.boolean "can_manage_support_tickets", default: false
    t.boolean "can_read_user_settings", default: false
    t.boolean "can_manage_user_settings", default: false
    t.string "role"
    t.boolean "can_manage_free_radius", default: false
    t.boolean "can_read_free_radius", default: false
    t.boolean "can_manage_mpesa_settings", default: false
    t.boolean "can_read_mpesa_settings", default: false
    t.boolean "can_reboot_router", default: false
    t.boolean "can_manage_user_group"
    t.boolean "can_read_user_group"
    t.boolean "can_manage_hotspot_template", default: false
    t.boolean "can_read_hotspot_template", default: false
    t.boolean "can_manage_hotspot_voucher", default: false
    t.boolean "can_read_hotspot_voucher", default: false
    t.boolean "can_manage_hotspot_settings", default: false
    t.boolean "can_read_hotspot_settings", default: false
    t.datetime "password_reset_sent_at"
    t.string "password_reset_token"
    t.string "status"
    t.datetime "last_login_at"
    t.string "otp_secret"
    t.text "otp_backup_codes", default: [], array: true
    t.boolean "otp_verified"
    t.datetime "last_activity_active"
    t.boolean "inactive"
    t.boolean "check_is_inactive"
    t.string "fcm_token"
    t.boolean "can_create_lead", default: false
    t.boolean "can_read_lead", default: false
    t.boolean "can_create_calendar_events", default: false
    t.boolean "can_read_calendar_events", default: false
    t.boolean "can_upload_subscriber", default: false
    t.boolean "can_send_bulk_sms", default: false
    t.boolean "can_send_single_sms", default: false
    t.boolean "can_read_ip_networks", default: false
    t.boolean "can_create_ip_networks", default: false
    t.boolean "can_create_wireguard_configuration", default: false
    t.boolean "can_read_task_setting", default: false
    t.boolean "can_create_task_setting", default: false
    t.boolean "can_create_license_setting", default: false
    t.boolean "can_read_license_setting", default: false
    t.boolean "can_manage_networks", default: false
    t.boolean "can_read_networks", default: false
    t.boolean "can_manage_private_ips", default: false
    t.boolean "can_read_private_ips", default: false
    t.boolean "can_read_invoice"
    t.boolean "can_manage_invoice"
    t.boolean "can_read_equipment"
    t.boolean "can_manage_equipment"
  end

  create_table "wireguard_peers", force: :cascade do |t|
    t.string "public_key"
    t.string "allowed_ips"
    t.integer "persistent_keepalive"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "account_id"
    t.string "private_ip"
    t.string "status"
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
