class CreatePresenterLookUps < ActiveRecord::Migration
  def self.up
    create_table :presenter_look_ups do |t|
      t.string :uuid, :null => false
      t.string :plate_purpose_name, :null => false
      t.string :presenter_class, :default => "PlatePresenter"
      t.timestamps
    end
  end

  def self.down
    drop_table :presenter_look_ups
  end
end
