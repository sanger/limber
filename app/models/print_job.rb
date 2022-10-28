# frozen_string_literal: true

class PrintJob # rubocop:todo Style/Documentation
  include ActiveModel::Model

  attr_reader :number_of_copies
  attr_accessor :printer, :printer_name, :label_templates_by_service, :labels, :labels_sprint

  # Add printer/ labels_sprint below?
  validates :printer_name, :label_templates_by_service, :number_of_copies, :labels, presence: true

  def execute
    return false unless valid?

    case printer.print_service
    when 'PMB'
      print_to_pmb
    when 'SPrint'
      print_to_sprint
    else
      errors.add(:base, "Print service #{printer.print_service} not recognised.")
      false
    end
  end

  def print_to_pmb # rubocop:disable all
    job =
      PMB::PrintJob.new(
        printer_name: printer_name,
        label_template_id: pmb_label_template_id,
        labels: {
          body: (labels * number_of_copies)
        }
      )
    if job.save
      true
    else
      errors.add(:print_server, job.errors.full_messages.join(' - '))
      false
    end
  rescue JsonApiClient::Errors::ConnectionError
    errors.add(:pmb, 'PrintMyBarcode service is down')
    false
  end

  def print_to_sprint
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
    #   },
    # ]

    # labels_sprint:
    # {
    #   "sprint"=> {
    #    "right_text"=>"DN9000003B",
    #    "left_text"=>"DN9000003B",
    #    "barcode"=>"DN9000003B",
    #    "extra_right_text"=>"DN9000003B  LTHR-384 RT",
    #    "extra_left_text"=>"10-NOV-2020"
    #   }
    # }

    label_template = get_label_template_by_service('SPrint')

    label_array = labels_sprint.values

    # label_array:
    # [{
    #   "right_text"=>"DN9000003B",
    #   "left_text"=>"DN9000003B",
    #   "barcode"=>"DN9000003B",
    #   "extra_right_text"=>"DN9000003B  LTHR-384 RT",
    #   "extra_left_text"=>"10-NOV-2020"
    # }]

    merge_fields_list = label_array * number_of_copies

    # assumes all labels use the same label template
    SPrintClient.send_print_request(printer_name, label_template, merge_fields_list)
    true
  end

  def number_of_copies=(number)
    @number_of_copies = number.to_i
  end

  private

  def pmb_label_template_id
    # This isn't a rails finder; so we disable the cop.
    PMB::LabelTemplate.where(name: get_label_template_by_service('PMB')).first.id
  rescue JsonApiClient::Errors::ConnectionError
    errors.add(:pmb, 'PrintMyBarcode service is down')
  end

  def get_label_template_by_service(print_service)
    templates_by_service = JSON.parse(label_templates_by_service)
    templates_by_service[print_service]
  end
end
