class FormLookUp < ActiveRecord::Base
  # self.primary_key = "uuid"

  def self.lookup(uuid)
    Forms.const_get(self.find(uuid).form_class)
  end
end
