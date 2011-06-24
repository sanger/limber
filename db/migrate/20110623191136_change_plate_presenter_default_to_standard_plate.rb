class ChangePlatePresenterDefaultToStandardPlate < ActiveRecord::Migration
  class PresenterLookUp < ActiveRecord::Base
    set_table_name('presenter_look_ups')
  end

  def self.change_default(current_default, new_default)
    change_column(:presenter_look_ups, :presenter_class, :string, :default => new_default)
    PresenterLookUp.reset_column_information
    PresenterLookUp.update_all(
      %Q{presenter_class="#{new_default}"},
      [ 'presenter_class=?', current_default ]
    )
  end

  def self.up
    change_default('PlatePresenter', 'StandardPresenter')
  end

  def self.down
    change_default('StandardPresenter', 'PlatePresenter')
  end
end
