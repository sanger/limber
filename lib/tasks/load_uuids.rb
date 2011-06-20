api = Sequencescape::Api.new(PulldownPipeline::Application.config.api_connection_options)

api.plate_purpose.all.each do |purpose|
  form_look_up = FormLookUp.find_by_plate_purpose_name(purpose.name)
  if form_look_up
    form_look_up.update_attributes( :uuid => purpose.uuid )
  else
    FormLookUp.create!(
      :plate_purpose_name => purpose.name,
      :uuid               => purpose.uuid
    ) 
  end
end
