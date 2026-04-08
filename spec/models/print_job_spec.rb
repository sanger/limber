# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PrintJob do
  let(:printer_pmb) { build :barcode_printer }
  let(:printer_sprint) { build :barcode_printer, print_service: 'SPrint' }
  let(:printer_unknown) { build :barcode_printer, print_service: 'UNKNOWN' }

  let(:label_template_id) { 1 }
  let(:label_template_name_pmb) { 'sqsc_96plate_label_template' }
  let(:label_template_name_sprint) { 'sqsc_96plate_label_template_sprint' }
  let(:label_templates_by_service) do
    JSON.generate({ 'PMB' => label_template_name_pmb, 'SPrint' => label_template_name_sprint })
  end

  let(:expected_labels) { [{ 'label' => { 'test_attr' => 'test', 'barcode' => '12345' } }] }
  let(:expected_sprint_labels) do
    { sprint: { 'extra_right_text' => 'some x right text', 'extra_left_text' => 'some x left text' } }
  end

  describe 'init' do
    it 'has the correct insatnce variables' do
      pj =
        described_class.new(
          printer_name: printer_pmb.name,
          printer: printer_pmb,
          label_templates_by_service: label_templates_by_service,
          labels: [{ 'label' => { 'barcode' => '12345', 'test_attr' => 'test' } }],
          labels_sprint: {
            sprint: {
              'extra_right_text' => 'some x right text',
              'extra_left_text' => 'some x left text'
            }
          },
          number_of_copies: 2
        )

      expect(pj.labels).to eq(expected_labels)
      expect(pj.labels_sprint).to eq(expected_sprint_labels)
      expect(pj.printer_name).to eq(printer_pmb.name)
      expect(pj.printer).to eq(printer_pmb)
      expect(pj.label_templates_by_service).to eq(label_templates_by_service)
      expect(pj.printer.print_service).to eq(printer_pmb.print_service)
    end
  end

  describe 'execute' do
    it 'calls print_to_pmb when service is PMB' do
      pj =
        described_class.new(
          printer_name: printer_pmb.name,
          printer: printer_pmb,
          label_templates_by_service: label_templates_by_service,
          labels: [{ 'label' => { 'barcode' => '12345', 'test_attr' => 'test' } }],
          labels_sprint: {
            sprint: {
              'extra_right_text' => 'some x right text',
              'extra_left_text' => 'some x left text'
            }
          },
          number_of_copies: 2
        )

      expect(pj).to receive(:print_to_pmb)
      pj.execute
    end

    it 'calls print_to_sprint when service is SPrint' do
      pj =
        described_class.new(
          printer_name: printer_sprint.name,
          printer: printer_sprint,
          label_templates_by_service: label_templates_by_service,
          labels: [{ 'label' => { 'barcode' => '12345', 'test_attr' => 'test' } }],
          labels_sprint: {
            sprint: {
              'extra_right_text' => 'some x right text',
              'extra_left_text' => 'some x left text'
            }
          },
          number_of_copies: 2
        )

      expect(pj).to receive(:print_to_sprint)
      pj.execute
    end

    it 'adds an error when service is down' do
      pj =
        described_class.new(
          printer_name: printer_unknown.name,
          printer: printer_unknown,
          label_templates_by_service: label_templates_by_service,
          labels: [{ 'label' => { 'barcode' => '12345', 'test_attr' => 'test' } }],
          labels_sprint: {
            sprint: {
              'extra_right_text' => 'some x right text',
              'extra_left_text' => 'some x left text'
            }
          },
          number_of_copies: 2
        )

      expect(pj.errors).to be_truthy
      pj.execute
    end
  end

  describe 'print_to_pmb' do
    let(:pmb_print_job) do
      PMB::PrintJob.new(
        printer_name: printer_pmb.name,
        label_template_id: label_template_id,
        labels: [{ label: { barcode: '12345', test_attr: 'test' } }]
      )
    end

    it 'sends post request to pmb if job is valid' do
      pj =
        described_class.new(
          printer_name: printer_pmb.name,
          printer: printer_pmb,
          label_templates_by_service: label_templates_by_service,
          labels: [{ label: { barcode: '12345', test_attr: 'test' } }],
          number_of_copies: 1
        )

      allow(pj).to receive(:pmb_label_template_id).and_return(label_template_id)
      allow(PMB::PrintJob).to receive(:new).and_return(pmb_print_job)
      allow(pmb_print_job).to receive(:save).and_return(true)

      expect(pj.print_to_pmb).to be(true)
    end

    it 'multiplies lablels if several copies required' do
      pj =
        described_class.new(
          printer_name: printer_pmb.name,
          printer: printer_pmb,
          label_templates_by_service: label_templates_by_service,
          labels: [
            { label: { barcode: '12345', test_attr: 'test' } },
            { label: { barcode: '67890', test_attr: 'test2' } }
          ],
          number_of_copies: 2
        )
      allow(pj).to receive(:pmb_label_template_id).and_return(label_template_id)
      allow(PMB::PrintJob).to receive(:new).and_return(pmb_print_job)
      allow(pmb_print_job).to receive(:save).and_return(false)

      expect(pj.print_to_pmb).to be(false)
    end

    it 'does not execute if pmb is down' do
      pj =
        described_class.new(
          printer_name: printer_pmb.name,
          printer: printer_pmb,
          label_templates_by_service: label_templates_by_service,
          labels: [{ label: { barcode: '12345', test_attr: 'test' } }],
          number_of_copies: 1
        )
      allow(PMB::LabelTemplate).to receive(:where).and_raise(JsonApiClient::Errors::ConnectionError.new('error'))
      expect(pj.execute).to be false
      expect(pj.errors.full_messages[0]).to eq('Pmb PrintMyBarcode service is down')
    end

    it 'does not execute if the pmb label template cannot be found' do
      pj =
        described_class.new(
          printer_name: printer_pmb.name,
          printer: printer_pmb,
          label_templates_by_service: label_templates_by_service,
          labels: [{ label: { barcode: '12345', test_attr: 'test' } }],
          number_of_copies: 1
        )

      allow(PMB::LabelTemplate).to receive(:where).and_return([])
      expect(pj.execute).to be false
      expect(pj.errors.full_messages[0]).to eq("Pmb Unable to find label template: #{label_template_name_pmb}")
    end
  end

  describe 'print_to_sprint' do
    let(:labels_sprint) do
      {
        'sprint' => {
          'right_text' => 'DN9000003B',
          'left_text' => 'DN9000003B',
          'barcode' => 'DN9000003B',
          'extra_right_text' => 'DN9000003B  LTHR-384 RT',
          'extra_left_text' => '10-NOV-2020'
        }
      }
    end

    let(:pj) do
      described_class.new(
        printer_name: printer_sprint.name,
        printer: printer_sprint,
        label_templates_by_service: label_templates_by_service,
        labels: [{ label: { barcode: '12345', test_attr: 'test' } }],
        labels_sprint: labels_sprint,
        number_of_copies: 1
      )
    end

    it 'sends a print request to SPrintClient' do
      allow(pj).to receive(:get_label_template_by_service).and_return(label_template_name_sprint)
      response = Net::HTTPSuccess.new(1.0, '200', 'OK')
      response.instance_variable_set(:@read, true)
      response.instance_variable_set(
        :@body,
        { data: { print: { jobId: 'psd-2:68b27056-11cf-41ff-9b22-bdf6121a95be' } } }.to_json
      )
      allow(SPrintClient).to receive(:send_print_request).and_return(response)
      expect(SPrintClient).to receive(:send_print_request).with(
        printer_sprint.name,
        label_template_name_sprint,
        labels_sprint.values
      )
      expect(pj.print_to_sprint).to be(true)
    end

    it 'does not execute if the SPrintClient is down' do
      response = Net::HTTPBadGateway.new(1.0, '502', nil)
      response.instance_variable_set(:@read, true)
      allow(SPrintClient).to receive(:send_print_request).and_return(response)
      expect(pj.execute).to be false
      expect(pj.errors.full_messages[0]).to eq('Sprint Trouble connecting to SPrint. Please try again later.')
    end

    it 'does not execute if the SPrintClient returns unprocessable entity' do
      response = Net::HTTPUnprocessableEntity.new(1.0, '422', nil)
      response.instance_variable_set(:@read, true)
      allow(SPrintClient).to receive(:send_print_request).and_return(response)
      expect(pj.execute).to be false
      expect(pj.errors.full_messages[0]).to eq(
        'Sprint Sprint could not understand the request. Please check the label data.'
      )
    end

    it 'does not execute if the SPrintClient returns unprocessable entity' do
      response = Net::HTTPInternalServerError.new(1.0, '500', nil)
      response.instance_variable_set(:@read, true)
      allow(SPrintClient).to receive(:send_print_request).and_return(response)
      expect(pj.execute).to be false
      expect(pj.errors.full_messages[0]).to eq('Sprint Internal server error at SPrint. Please try again later.')
    end

    it 'does not execute if the SPrintClient sends a valid error with code 200' do
      response = Net::HTTPSuccess.new(1.0, '200', nil)
      response.instance_variable_set(:@read, true)
      response.instance_variable_set(
        :@body,
        {
          errors: [
            {
              message: "Variable 'printRequest' has an invalid value: Expected type 'Int' but was 'Double'.",
              locations: [{ line: 1, column: 16 }],
              extensions: {
                classification: 'ValidationError'
              }
            }
          ]
        }.to_json
      )
      allow(SPrintClient).to receive(:send_print_request).and_return(response)
      expect(pj.execute).to be false
      expect(pj.errors.full_messages[0]).to eq(
        "Sprint Variable 'printRequest' has an invalid value: Expected type 'Int' but was 'Double'. (ValidationError)"
      )
    end

    it 'does not execute if the SPrintClient sends an invalid error with code 200' do
      response = Net::HTTPSuccess.new(1.0, '200', nil)
      response.instance_variable_set(:@read, true)
      response.instance_variable_set(
        :@body,
        {
          errors: [
            {
              message: 'Failed to parse JSON response from SprintClient',
              locations: [{ line: 1, column: 16 }],
              extensions: {
                classification: 'ValidationError'
              }
            }
          ]
        }.to_json
      )
      allow(SPrintClient).to receive(:send_print_request).and_return(response)
      expect(pj.execute).to be false
      expect(pj.errors.full_messages[0]).to eq(
        'Sprint Failed to parse JSON response from SprintClient (ValidationError)'
      )
    end
  end

  describe '#extract_error_message' do
    let(:print_job) { described_class.new }

    it 'returns the error message with extensions' do
      response =
        instance_double(
          'Net::HTTPResponse',
          body: {
            errors: [
              {
                message: "Variable 'printRequest' has an invalid value: Expected type 'Int' but was 'Double'.",
                extensions: {
                  classification: 'ValidationError'
                }
              }
            ]
          }.to_json
        )

      expect(print_job.send(:extract_error_message, response)).to eq(
        "Variable 'printRequest' has an invalid value: Expected type 'Int' but was 'Double'. (ValidationError)"
      )
    end

    it 'returns the error message without extensions' do
      response =
        instance_double(
          'Net::HTTPResponse',
          body: {
            errors: [{ message: "Variable 'printRequest' has an invalid value: Expected type 'Int' but was 'Double'." }]
          }.to_json
        )

      expect(print_job.send(:extract_error_message, response)).to eq(
        "Variable 'printRequest' has an invalid value: Expected type 'Int' but was 'Double'."
      )
    end

    it 'returns unknown error if response body is empty' do
      response = instance_double('Net::HTTPResponse', body: nil)

      expect(print_job.send(:extract_error_message, response)).to eq('Unknown error')
    end

    it 'returns failed to parse JSON response if JSON parsing fails' do
      response = instance_double('Net::HTTPResponse', body: 'invalid_json')

      expect(print_job.send(:extract_error_message, response)).to eq('Failed to parse JSON response from SprintClient')
    end
  end
end
