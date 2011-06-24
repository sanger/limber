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
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20110623191136) do

  create_table "form_look_ups", :force => true do |t|
    t.string   "uuid",                                           :null => false
    t.string   "plate_purpose_name",                             :null => false
    t.string   "form_class",         :default => "CreationForm"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "presenter_look_ups", :force => true do |t|
    t.string   "uuid",                                                :null => false
    t.string   "plate_purpose_name",                                  :null => false
    t.string   "presenter_class",    :default => "StandardPresenter"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
