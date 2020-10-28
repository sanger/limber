# frozen_string_literal: true

class PrintJob # rubocop:todo Style/Documentation
  include ActiveModel::Model

  attr_reader :number_of_copies
  attr_accessor :labels, :printer_name, :label_template

  validates :printer_name, :label_template, :number_of_copies, :labels, presence: true

  def execute # rubocop:todo Metrics/MethodLength
    return false unless valid?

    begin
      # if printer type is PMB
      # job = PMB::PrintJob.new(
      #   printer_name: printer_name,
      #   label_template_id: label_template_id,
      #   labels: { body: all_labels }
      # )
      # if job.save
      #   true
      # else
      #   errors.add(:print_server, job.errors.full_messages.join(' - '))
      #   false
      # end

      # if printer type is Squix / SPrint
      # TODO: get attributes into here through PlateLabel and hidden fields
      response = SprintClient.send_print_request(
        printer_name,
        label_template,
        [
          {
            barcode: "DN111111",
            date: "1-APR-2020",
            barcode_text: "DN111111",
            workline_identifier: "DN111111",
            order_role: "Heron",
            plate_purpose: "LHR PCR 1"
          }
        ]
      )
      puts "response: #{response}"

    rescue JsonApiClient::Errors::ConnectionError
      errors.add(:pmb, 'PrintMyBarcode service is down')
      false
    end
  end

  def number_of_copies=(number)
    @number_of_copies = number.to_i
  end

  private

  def label_template_id
    # This isn't a rails finder; so we disable the cop.
    PMB::LabelTemplate.where(name: label_template).first.id
  rescue JsonApiClient::Errors::ConnectionError
    errors.add(:pmb, 'PrintMyBarcode service is down')
  end

  def all_labels
    labels * number_of_copies
  end
end
