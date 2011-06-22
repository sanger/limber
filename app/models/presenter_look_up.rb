class PresenterLookUp < ActiveRecord::Base
  def self.lookup(uuid)
    Presenters.const_get(self.find_by_uuid(uuid).presenter_class)
  end
end
