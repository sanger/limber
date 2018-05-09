# frozen_string_literal: true

class PrintJob
  include ActiveModel::Model

  attr_reader :number_of_copies
  attr_accessor :labels, :printer_name, :label_template

  validates :printer_name, :label_template, :number_of_copies, :labels, presence: true

  def execute
    return false unless valid?
    begin
      job = PMB::PrintJob.new(
        printer_name: printer_name,
        label_template_id: label_template_id,
        labels: { body: all_labels }
      )
      if job.save
        true
      else
        errors.add(:print_server, job.errors.full_messages.join(' - '))
        false
      end
    rescue JsonApiClient::Errors::ConnectionError
      errors.add(:pmb, 'PrintMyBarcode service is down')
      return false
    end
  end

  def number_of_copies=(number)
    @number_of_copies = number.to_i
  end

  private

  def label_template_id
    # This isn't a rails finder; so we disable the cop.
    PMB::LabelTemplate.where(name: label_template).first.id # rubocop:disable Rails/FindBy
  rescue JsonApiClient::Errors::ConnectionError
    errors.add(:pmb, 'PrintMyBarcode service is down')
  end

  def all_labels
    labels * number_of_copies
  end
end
