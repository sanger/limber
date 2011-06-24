api = Sequencescape::Api.new(PulldownPipeline::Application.config.api_connection_options)

api.plate_purpose.all.each do |purpose|
  [ FormLookUp, PresenterLookUp ].each do |klass|
    form_look_up = klass.find_by_plate_purpose_name(purpose.name)
    if form_look_up
      form_look_up.update_attributes( :uuid => purpose.uuid )
    else
      klass.create!(
        :plate_purpose_name => purpose.name,
        :uuid               => purpose.uuid
      )

    end
  end
end

# Set custom forms...
{
  "WGS library plate"                  => "TransferForm",
  "WGS library PCR plate"              => "TaggingForm",
  "WGS pooled amplified library plate" => "AutoPoolingForm"
}.each do |plate_purpose, form_class|
  FormLookUp.find_by_plate_purpose_name(plate_purpose).update_attributes(
    :form_class => form_class
  )
end


# Set custom presenters...
{
  "WGS pooled amplified library plate" => "PooledPresenter",
  "SC pooled captured library plate"   => "PooledPresenter",
  "ISC pooled amplified library plate" => "PooledPresenter",
  "WGS library PCR plate"              => "TaggedPresenter"
}.each do |plate_purpose, presenter_class|
  PresenterLookUp.find_by_plate_purpose_name(plate_purpose).update_attributes(
    :presenter_class => presenter_class
  )
end
