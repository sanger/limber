module Forms
  class TubesForm < CreationForm

    def create_objects!
      api.transfer_template.find(Settings.transfer_templates["Transfer wells to MX library tubes by submission"]).create!(
        :source => parent_uuid
      )
     true
    rescue => e
      false
    end
  end
end
