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

ActiveRecord::Schema[7.2].define(version: 2025_07_01_173450) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "accounts", force: :cascade do |t|
    t.string "subdomain"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "domain"
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
  end

  create_table "client_mac_adresses", force: :cascade do |t|
    t.string "macadress"
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

  create_table "general_settings", force: :cascade do |t|
    t.string "title"
    t.string "timezone"
    t.string "allowed_ips", default: [], array: true
    t.integer "account_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
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
  end

  create_table "hotspot_plans", force: :cascade do |t|
    t.string "name"
    t.string "hotspot_subscribers"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "account_id"
    t.datetime "expiry_days"
    t.string "billing_cycle"
    t.string "status"
    t.boolean "condition"
    t.datetime "expiry"
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
  end

  create_table "nodes", force: :cascade do |t|
    t.string "name"
    t.string "latitude"
    t.string "longitude"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "country"
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
  end

  create_table "pp_poe_plans", force: :cascade do |t|
    t.string "maximum_pppoe_subscribers"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name"
    t.datetime "expiry"
    t.integer "account_id"
    t.datetime "expiry_days"
    t.string "billing_cycle"
    t.string "status"
    t.boolean "condition"
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
  end

  create_table "wireguard_peers", force: :cascade do |t|
    t.string "public_key"
    t.string "allowed_ips"
    t.integer "persistent_keepalive"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "account_id"
    t.string "private_ip"
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
