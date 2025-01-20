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

  def print_to_pmb
    # Ensure the template exists before attempting to print
    label_template_id = pmb_label_template_id
    return false if label_template_id.nil?

    job =
      PMB::PrintJob.new(
        printer_name: printer_name,
        label_template_id: label_template_id,
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

    label_array = labels_sprint.values.flatten

    # label_array:
    # [{
    #   "right_text"=>"DN9000003B",
    #   "left_text"=>"DN9000003B",
    #   "barcode"=>"DN9000003B",
    #   "extra_right_text"=>"DN9000003B  LTHR-384 RT",
    #   "extra_left_text"=>"10-NOV-2020"
    # }]

    merge_fields_list = label_array * number_of_copies

    response = SPrintClient.send_print_request(printer_name, label_template, merge_fields_list)

    handle_sprint_response(response)
  end

  def number_of_copies=(number)
    @number_of_copies = number.to_i
  end

  private

  def pmb_label_template_id
    pmb_label_template = get_label_template_by_service('PMB')
    template_id = PMB::LabelTemplate.where(name: pmb_label_template).first&.id
    if template_id.nil?
      errors.add(:pmb, "Unable to find label template: #{pmb_label_template}")
      nil
    else
      template_id
    end
  rescue JsonApiClient::Errors::ConnectionError
    errors.add(:pmb, 'PrintMyBarcode service is down')
    nil
  end

  def get_label_template_by_service(print_service)
    templates_by_service = JSON.parse(label_templates_by_service)
    templates_by_service[print_service]
  end

  # Handles the response from the SPrintClient and checks for success.
  # If the response is successful and contains a job ID, it returns true.
  # Otherwise, it adds an error message to the errors object and returns false.
  #
  # The print_to_sprint call fails silently if there is an error. Instead
  # of returning success, the result of the send_print_request call should
  # be used to check the response status and response body. Examples:
  #
  # The following response body is returned in a 200 response.
  # {"errors":[{"message":"Variable 'printRequest' has an invalid value: Expected
  #   type 'Int' but was
  #   'Double'.","locations":[{"line":1,"column":16}],"extensions":{"classification":"
  #   ValidationError"}}]}
  #
  # The following response body is returned in a 500 response.
  # {"timestamp": "2023-08-02T14:46:30.160+00:00","status": 500,"error": "Internal
  #   Server Error","path": "/graphql"}
  #
  # When sprint cannot log in to printer, the details are available in response body.
  #
  # A successful response has a job id in response body.
  #
  # Use errors.add to show proper feedback in the view.
  #
  # @param response [Net::HTTPResponse] The response object from the SPrintClient.
  # @return [Boolean] True if the response is successful and contains a job ID, false otherwise.
  def handle_sprint_response(response)
    # Non-200 errors are treated as failures
    # Ref: https://ruby-doc.org/stdlib-2.7.0/libdoc/net/http/rdoc/Net/HTTP.html#class-Net::HTTP-label-GET+with+Dynamic+Parameters
    unless response.is_a?(Net::HTTPSuccess)
      errors.add(
        :sprint,
        "Trouble connecting to SPrint. Please try again later."
      )
      return false
    end
    if response.body.present? && response.body['jobId'].present?
      true
    else
      errors.add(:sprint, extract_error_message(response))
      false
    end
  end

  def extract_error_message(response)
    if response.body.present?
      begin
        response_body = JSON.parse(response.body)
        return response_body['errors'].pluck('message').join(' - ') if response_body['errors'].present?
      rescue JSON::ParserError
        return 'Failed to parse JSON response from SprintClient'
      end
    end
    'Unknown error'
  end
end
