class PrintJob

  include ActiveModel::Model
  attr_accessor :labels, :printer_name, :printer_type, :number_of_copies

  validates_presence_of :printer_name, :printer_type, :number_of_copies, :labels

  def execute
    return false unless valid?
    begin
      job = PMB::PrintJob.new(
        printer_name: printer_name,
        label_template_id: label_template_id,
        labels: {body: all_labels}
      )
      if job.save
        true
      else
        errors.add(:print_server,job.errors.full_messages.join(' - '))
        false
      end
    rescue JsonApiClient::Errors::ConnectionError => e
      errors.add(:pmb, "PrintMyBarcode service is down")
      return false
    end
  end

  private

  def label_template_id
    label_template_name = Settings.label_templates[printer_type]
    PMB::LabelTemplate.where(name: label_template_name).first.id
  rescue JsonApiClient::Errors::ConnectionError => e
    errors.add(:pmb, "PrintMyBarcode service is down")
  end

  def all_labels
    labels*number_of_copies
  end

end