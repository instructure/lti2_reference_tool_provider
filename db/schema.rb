# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20170313191804) do

  create_table "oauth_nonces", force: :cascade do |t|
    t.string "value", null: false
    t.index ["value"], name: "index_oauth_nonces_on_value"
  end

  create_table "tool_proxies", force: :cascade do |t|
    t.string "guid",                  null: false
    t.string "shared_secret",         null: false
    t.string "tcp_url",               null: false
    t.string "base_url",              null: false
    t.string "tp_half_shared_secret"
    t.index ["guid"], name: "index_tool_proxies_on_guid"
  end

end
