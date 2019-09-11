class SetupSchema < ActiveRecord::Migration
  def change
    create_table "arrangements", force: :cascade do |t|
      t.boolean  "use_scrap",                   default: true
      t.boolean  "use_scrap_minimum"
      t.integer  "scrap_minimum",     limit: 4
      t.integer  "customer_id",       limit: 4
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    create_table "arrivals", force: :cascade do |t|
      t.decimal  "temperature",                precision: 8, scale: 3
      t.integer  "customer_id",    limit: 4
      t.datetime "created_at"
      t.datetime "updated_at"
      t.datetime "arrived_at"
      t.integer  "pallet_count",   limit: 4
      t.integer  "count",          limit: 4
      t.integer  "pallet_type_id", limit: 4
      t.integer  "capacity",       limit: 4
      t.decimal  "weight",                     precision: 8, scale: 3
      t.string   "number",         limit: 255
      t.string   "batch",          limit: 255
      t.string   "name",           limit: 255
      t.string   "trace",          limit: 255
      t.date     "best_before"
    end

    create_table "customer_groups", force: :cascade do |t|
      t.string   "name",          limit: 255
      t.text     "data",          limit: 65535
      t.integer  "department_id", limit: 4
      t.datetime "created_at",                  null: false
      t.datetime "updated_at",                  null: false
    end

    add_index "customer_groups", ["department_id"], name: "index_customer_groups_on_department_id", using: :btree

    create_table "customers", force: :cascade do |t|
      t.string   "name",           limit: 255
      t.string   "number",         limit: 255
      t.string   "subname",        limit: 255
      t.string   "address",        limit: 255
      t.string   "phone",          limit: 255
      t.string   "fax",            limit: 255
      t.string   "email",          limit: 255
      t.integer  "position",       limit: 4
      t.integer  "department_id",  limit: 4
      t.datetime "created_at"
      t.datetime "updated_at"
      t.text     "barcode_format", limit: 65535
      t.boolean  "deactivated",                  default: false
    end

    create_table "departments", force: :cascade do |t|
      t.string   "label",                limit: 255
      t.string   "address",              limit: 255
      t.integer  "lobby_id",             limit: 4
      t.integer  "transfer_id",          limit: 4
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string   "name",                 limit: 255
      t.string   "authorization_number", limit: 255
    end

    create_table "intervals", force: :cascade do |t|
      t.datetime "from"
      t.datetime "to"
      t.integer  "customer_id", limit: 4
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    create_table "notes", force: :cascade do |t|
      t.string   "content",     limit: 255
      t.integer  "customer_id", limit: 4
      t.datetime "created_at"
      t.datetime "updated_at"
      t.datetime "posted_at"
    end

    create_table "order_imports", force: :cascade do |t|
      t.string   "file",                limit: 255
      t.integer  "owner_id",            limit: 4
      t.integer  "customer_group_id",   limit: 4
      t.text     "data",                limit: 65535
      t.string   "state",               limit: 255
      t.string   "number",              limit: 255
      t.date     "load_at"
      t.date     "deliver_at"
      t.string   "destination_name",    limit: 255
      t.string   "destination_address", limit: 255
      t.text     "note",                limit: 65535
      t.datetime "created_at",                        null: false
      t.datetime "updated_at",                        null: false
    end

    add_index "order_imports", ["customer_group_id"], name: "index_order_imports_on_customer_group_id", using: :btree
    add_index "order_imports", ["owner_id"], name: "index_order_imports_on_owner_id", using: :btree

    create_table "orders", force: :cascade do |t|
      t.string   "number",              limit: 255
      t.date     "load_at"
      t.date     "deliver_at"
      t.string   "destination_name",    limit: 255
      t.string   "destination_address", limit: 255
      t.text     "note",                limit: 65535
      t.string   "state",               limit: 255
      t.integer  "customer_id",         limit: 4
      t.datetime "created_at"
      t.datetime "updated_at"
      t.datetime "done_at"
      t.integer  "owner_id",            limit: 4
      t.integer  "order_import_id",     limit: 4
      t.string   "delivery",            limit: 255
    end

    add_index "orders", ["customer_id"], name: "index_orders_on_customer_id", using: :btree
    add_index "orders", ["done_at"], name: "index_orders_on_done_at", using: :btree
    add_index "orders", ["order_import_id"], name: "index_orders_on_order_import_id", using: :btree
    add_index "orders", ["owner_id"], name: "index_orders_on_owner_id", using: :btree

    create_table "pallet_corrections", force: :cascade do |t|
      t.integer  "count",          limit: 4
      t.integer  "capacity",       limit: 4
      t.decimal  "weight",                   precision: 8, scale: 3
      t.integer  "pallet_type_id", limit: 4
      t.integer  "pallet_id",      limit: 4
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    add_index "pallet_corrections", ["created_at"], name: "index_pallet_corrections_on_created_at", using: :btree
    add_index "pallet_corrections", ["pallet_id"], name: "index_pallet_corrections_on_pallet_id", using: :btree

    create_table "pallets", force: :cascade do |t|
      t.string   "name",                     limit: 255
      t.string   "number",                   limit: 255
      t.string   "batch",                    limit: 255
      t.string   "trace",                    limit: 255
      t.decimal  "original_weight",                      precision: 8, scale: 3
      t.integer  "original_count",           limit: 4
      t.integer  "original_capacity",        limit: 4
      t.date     "best_before"
      t.datetime "deleted_at"
      t.integer  "customer_id",              limit: 4
      t.integer  "original_pallet_type_id",  limit: 4
      t.integer  "position_id",              limit: 4
      t.string   "position_type",            limit: 255
      t.integer  "arrival_id",               limit: 4
      t.datetime "created_at"
      t.datetime "updated_at"
      t.integer  "reserved",                 limit: 4
      t.integer  "taken",                    limit: 4
      t.integer  "corrected_count",          limit: 4
      t.integer  "corrected_capacity",       limit: 4
      t.integer  "corrected_pallet_type_id", limit: 4
      t.decimal  "corrected_weight",                     precision: 8, scale: 3
      t.datetime "arrived_at"
    end

    add_index "pallets", ["customer_id"], name: "index_pallets_on_customer_id", using: :btree
    add_index "pallets", ["position_id"], name: "pallets_position_id", using: :btree

    create_table "placements", force: :cascade do |t|
      t.integer  "shelf",                limit: 4
      t.integer  "column",               limit: 4
      t.integer  "floor",                limit: 4
      t.boolean  "hidden",                         default: false
      t.integer  "organized_storage_id", limit: 4
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    create_table "reservations", force: :cascade do |t|
      t.integer  "count",      limit: 4
      t.integer  "order_id",   limit: 4
      t.integer  "pallet_id",  limit: 4
      t.datetime "created_at"
      t.datetime "updated_at"
      t.datetime "done_at"
    end

    add_index "reservations", ["order_id"], name: "index_reservations_on_order_id", using: :btree
    add_index "reservations", ["pallet_id"], name: "index_reservations_on_pallet_id", using: :btree

    create_table "storages", force: :cascade do |t|
      t.string   "name",          limit: 255
      t.string   "type",          limit: 255
      t.integer  "department_id", limit: 4
      t.integer  "position",      limit: 4
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    create_table "users", force: :cascade do |t|
      t.string   "email",                  limit: 255,   default: "", null: false
      t.string   "encrypted_password",     limit: 128,   default: "", null: false
      t.string   "reset_password_token",   limit: 255
      t.integer  "failed_attempts",        limit: 4,     default: 0
      t.string   "unlock_token",           limit: 255
      t.datetime "locked_at"
      t.datetime "remember_created_at"
      t.integer  "sign_in_count",          limit: 4,     default: 0
      t.datetime "current_sign_in_at"
      t.datetime "last_sign_in_at"
      t.string   "current_sign_in_ip",     limit: 255
      t.string   "last_sign_in_ip",        limit: 255
      t.string   "username",               limit: 255
      t.string   "full_name",              limit: 255
      t.string   "phone",                  limit: 255
      t.string   "role",                   limit: 255
      t.datetime "created_at"
      t.datetime "updated_at"
      t.datetime "reset_password_sent_at"
      t.text     "permissions",            limit: 65535
    end

    add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
    add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree
    add_index "users", ["unlock_token"], name: "index_users_on_unlock_token", unique: true, using: :btree
    add_index "users", ["username"], name: "index_users_on_username", unique: true, using: :btree

    add_foreign_key "customer_groups", "departments"
    add_foreign_key "order_imports", "customer_groups"
  end
end
