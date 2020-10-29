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
      # N.B. this will not currently work for labels that use 'double' labels,
      # because templates are not implemented that use right_text, left_text etc.

      # labels structure is like this:
      # "labels"=>[
      #   {
      #     "main_label"=>{
      #       "top_left"=>"29-OCT-2020",
      #       "bottom_left"=>"DN9000214K",
      #       "top_right"=>"DN9000211H",
      #       "bottom_right"=>"Duplex-Seq LDS AL Lib",
      #       "barcode"=>"DN9000214K"
      #     },
      #     "extra_label"=>{
      #       "top_left"=>"29-OCT-2020",
      #       "bottom_left"=>"DN9000214K",
      #       "top_right"=>"DN9000211H",
      #       "bottom_right"=>"Duplex-Seq LDS AL Lib extra",
      #       "barcode"=>"DN9000214K"
      #     }
      #   },
      #   {
      #     "main_label"=>{
      #       "top_left"=>"29-OCT-2020",
      #       "bottom_left"=>"DN9000214K",
      #       "top_right"=>"DN9000211H",
      #       "bottom_right"=>"Duplex-Seq LDS Lig",
      #       "barcode"=>"DN9000214K-LIG"
      #     }
      #   }
      # ]
      label_array = []
      labels.each do |label|
        # Not sure why PMB treats main_label and extra_label differently
        # so we'll just add them both as separate labels
        label_array << label.values
      end

      # assumes all labels use the same label template
      response = SPrintClient.send_print_request(
        printer_name,
        label_template,
        label_array * number_of_copies
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
