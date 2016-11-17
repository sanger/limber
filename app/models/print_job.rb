class PrintJob

  include ActiveModel::Model
  attr_accessor :labels, :printer_name, :printer_type, :number_of_copies

  validates_presence_of :printer_name, :printer_type, :number_of_copies, :labels

  def execute
    return false unless valid?
    job = PMB::PrintJob.new(
      printer_name: printer_name,
      label_template_id: label_template_id,
      labels: {body: (labels*number_of_copies)}
    )
    if job.save
      true
    else
      errors.add(:print_server,job.errors.full_messages.join(' - '))
      false
    end
  end

  private

  def label_template_id
    label_template_name = Settings.label_templates[printer_type]
    PMB::LabelTemplate.where(name: label_template_name).first.id
  end

end