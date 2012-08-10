module Forms
  class TubesForm < CreationForm

    def create_objects!
      transfer_return = api.transfer_template.find(
        Settings.transfer_templates["Transfer from tube to tube by submission"]
      ).create!(
        :user   => user_uuid,
        :source => parent_uuid
      )
     true
    rescue => e
      false
    end


  end

end
