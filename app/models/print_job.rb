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

  def print_to_pmb # rubocop:todo Metrics/MethodLength
    job = PMB::PrintJob.new(
      printer_name: printer_name,
      label_template_id: pmb_label_template_id,
      labels: { body: (labels * number_of_copies) }
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

    # "labels_sprint"=>{
    #   "sprint"=>{"a"=>" 3-NOV-2020", "b"=>"DN9000210G", "c"=>"DN9000210G", "d"=>"Duplex-Seq LDS Stock", "e"=>"DN9000210G", "f"=>"hello"},
    #   "interm_0"=>{"l"=>"Int 1", "m"=>"DN9000210G", "n"=>"DN9000210G", "o"=>"Duplex-Seq LDS Lig", "p"=>"DN9000210G-LIG"},
    #   "interm_1"=>{"q"=>"Int 2", "r"=>"DN9000210G", "s"=>"DN9000210G", "t"=>"Duplex-Seq LDS A-tail", "u"=>"DN9000210G-ATL"},
    #   "interm_2"=>{"v"=>"Int 3", "w"=>"DN9000210G", "x"=>"DN9000210G", "y"=>"Duplex-Seq LDS Frag", "z"=>"DN9000210G-FRG"},
    #   "qc_0"=>{"g"=>"QC 1", "h"=>"QC 1", "i"=>"QC 1"},
    #   "qc_1"=>{"j"=>"QC 2", "k"=>"QC 2"}
    # }

    label_template = get_label_template_by_service('SPrint')
    # puts "label_template: #{label_template}"

    label_array = labels_sprint.values
    # puts "label_array: #{label_array}"

    # assumes all labels use the same label template
    SPrintClient.send_print_request(
      printer_name,
      label_template,
      label_array * number_of_copies
    )
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
