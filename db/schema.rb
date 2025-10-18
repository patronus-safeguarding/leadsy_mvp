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

ActiveRecord::Schema[7.1].define(version: 2025_10_18_122816) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "uuid-ossp"

  create_table "access_grants", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "access_request_id", null: false
    t.uuid "integration_provider_id", null: false
    t.string "provider_account_id", null: false
    t.datetime "token_expires_at"
    t.string "status", default: "active", null: false
    t.jsonb "assets", default: [], null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "access_token"
    t.text "refresh_token"
    t.index ["access_request_id", "integration_provider_id"], name: "idx_access_grants_unique_request_provider", unique: true
    t.index ["access_request_id"], name: "index_access_grants_on_access_request_id"
    t.index ["integration_provider_id"], name: "index_access_grants_on_integration_provider_id"
    t.index ["provider_account_id"], name: "index_access_grants_on_provider_account_id"
    t.index ["status"], name: "index_access_grants_on_status"
  end

  create_table "access_requests", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "access_template_id", null: false
    t.uuid "client_id", null: false
    t.string "token", null: false
    t.datetime "expires_at", null: false
    t.string "status", default: "pending", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["access_template_id"], name: "index_access_requests_on_access_template_id"
    t.index ["client_id"], name: "index_access_requests_on_client_id"
    t.index ["expires_at"], name: "index_access_requests_on_expires_at"
    t.index ["status"], name: "index_access_requests_on_status"
    t.index ["token"], name: "index_access_requests_on_token", unique: true
  end

  create_table "access_templates", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.jsonb "provider_scopes", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "user_id", null: false
    t.index ["name"], name: "index_access_templates_on_name"
    t.index ["user_id"], name: "index_access_templates_on_user_id"
  end

  create_table "audit_events", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "auditable_type", null: false
    t.uuid "auditable_id", null: false
    t.string "action", null: false
    t.jsonb "audit_changes", default: {}, null: false
    t.uuid "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["action"], name: "index_audit_events_on_action"
    t.index ["auditable_type", "auditable_id"], name: "index_audit_events_on_auditable"
    t.index ["auditable_type", "auditable_id"], name: "index_audit_events_on_auditable_type_and_auditable_id"
    t.index ["created_at"], name: "index_audit_events_on_created_at"
    t.index ["user_id"], name: "index_audit_events_on_user_id"
  end

  create_table "clients", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.string "email", null: false
    t.string "company"
    t.string "phone"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company"], name: "index_clients_on_company"
    t.index ["email"], name: "index_clients_on_email"
  end

  create_table "integration_providers", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.string "provider_type", null: false
    t.string "base_url"
    t.string "client_id", null: false
    t.text "client_secret_encrypted"
    t.string "oauth_authorize_url", null: false
    t.string "oauth_token_url", null: false
    t.jsonb "scopes", default: [], null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_integration_providers_on_name"
    t.index ["provider_type"], name: "index_integration_providers_on_provider_type"
  end

  create_table "users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.string "agency_name"
    t.boolean "is_owner", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["agency_name"], name: "index_users_on_agency_name"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["is_owner"], name: "index_users_on_is_owner"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "access_grants", "access_requests"
  add_foreign_key "access_grants", "integration_providers"
  add_foreign_key "access_requests", "access_templates"
  add_foreign_key "access_requests", "clients"
  add_foreign_key "access_templates", "users"
  add_foreign_key "audit_events", "users"
end
