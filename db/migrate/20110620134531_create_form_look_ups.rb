class CreateFormLookUps < ActiveRecord::Migration
  def self.up
    create_table :form_look_ups do |t|
      t.string :uuid               , :null    => false
      t.string :plate_purpose_name , :null    => false
      t.string :form_class         , :default => "CreationForm"
      t.timestamps
    end
  end

  def self.down
    drop_table :form_look_ups
  end
end
