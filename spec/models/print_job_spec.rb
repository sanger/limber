# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PrintJob do
  has_a_working_api

  let(:printer_pmb) { build :barcode_printer }
  let(:printer_sprint) { build :barcode_printer, print_service: 'SPrint' }
  let(:printer_unknown) { build :barcode_printer, print_service: 'UNKNOWN' }

  let(:label_template_id) { 1 }
  let(:label_template_name_pmb) { 'sqsc_96plate_label_template' }
  let(:label_template_name_sprint)  { 'sqsc_96plate_label_template_sprint' }
  let(:label_templates_by_service)  { JSON.generate({ 'PMB' => label_template_name_pmb, 'SPrint' => label_template_name_sprint }) }
  let(:label_template_query)        { { 'filter[name]': label_template_name_pmb, 'page[page]': 1, 'page[per_page]': 1 } }
  let(:label_template_url)          { "/v1/label_templates?#{URI.encode_www_form(label_template_query)}" }

  let(:expected_labels)         { [{ 'label' => { 'test_attr' => 'test', 'barcode' => '12345' } }] }
  let(:expected_sprint_labels)  { { 'sprint': { 'extra_right_text' => 'some x right text', 'extra_left_text' => 'some x left text' } } }

  describe 'init' do
    it 'has the correct insatnce variables' do
      pj = PrintJob.new(
        printer_name: printer_pmb.name,
        printer: printer_pmb,
        label_templates_by_service: label_templates_by_service,
        labels: [
          { 'label' => { 'barcode' => '12345', 'test_attr' => 'test' } }
        ],
        labels_sprint: {
          'sprint': { 'extra_right_text' => 'some x right text', 'extra_left_text' => 'some x left text' }
        },
        number_of_copies: 2
      )

      assert_equal expected_labels, pj.labels
      assert_equal expected_sprint_labels, pj.labels_sprint
      assert_equal printer_pmb.name, pj.printer_name
      assert_equal printer_pmb, pj.printer
      assert_equal label_templates_by_service, pj.label_templates_by_service
      assert_equal printer_pmb.print_service, pj.printer.print_service
    end
  end

  describe 'execute' do
    it 'calls print_to_pmb when service is PMB' do
      pj = PrintJob.new(
        printer_name: printer_pmb.name,
        printer: printer_pmb,
        label_templates_by_service: label_templates_by_service,
        labels: [
          { 'label' => { 'barcode' => '12345', 'test_attr' => 'test' } }
        ],
        labels_sprint: {
          'sprint': { 'extra_right_text' => 'some x right text', 'extra_left_text' => 'some x left text' }
        },
        number_of_copies: 2
      )

      expect(pj).to receive(:print_to_pmb)
      pj.execute
    end

    it 'calls print_to_sprint when service is SPrint' do
      pj = PrintJob.new(
        printer_name: printer_sprint.name,
        printer: printer_sprint,
        label_templates_by_service: label_templates_by_service,
        labels: [
          { 'label' => { 'barcode' => '12345', 'test_attr' => 'test' } }
        ],
        labels_sprint: {
          'sprint': { 'extra_right_text' => 'some x right text', 'extra_left_text' => 'some x left text' }
        },
        number_of_copies: 2
      )

      expect(pj).to receive(:print_to_sprint)
      pj.execute
    end

    it 'adds an error when service is down' do
      pj = PrintJob.new(
        printer_name: printer_unknown.name,
        printer: printer_unknown,
        label_templates_by_service: label_templates_by_service,
        labels: [
          { 'label' => { 'barcode' => '12345', 'test_attr' => 'test' } }
        ],
        labels_sprint: {
          'sprint': { 'extra_right_text' => 'some x right text', 'extra_left_text' => 'some x left text' }
        },
        number_of_copies: 2
      )

      expect(pj.errors).to be_truthy
      pj.execute
    end
  end

  describe 'print_to_pmb' do
    let(:pmb_print_job) do
      PMB::PrintJob.new(printer_name: printer_pmb.name,
                        label_template_id: label_template_id,
                        labels: [{ label: { barcode: '12345', test_attr: 'test' } }])
    end

    it 'should send post request to pmb if job is valid' do
      pj = PrintJob.new(
        printer_name: printer_pmb.name,
        printer: printer_pmb,
        label_templates_by_service: label_templates_by_service,
        labels: [{ label: { barcode: '12345', test_attr: 'test' } }],
        number_of_copies: 1
      )

      allow(pj).to receive(:pmb_label_template_id).and_return(label_template_id)
      allow(PMB::PrintJob).to receive(:new).and_return(pmb_print_job)
      allow(pmb_print_job).to receive(:save).and_return(true)

      expect(pj.print_to_pmb).to eq(true)
    end

    it 'should multiply lablels if several copies required' do
      pj = PrintJob.new(
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

      expect(pj.print_to_pmb).to eq(false)
    end

    it 'should not execute if pmb is down' do
      stub_request(:get, "http://localhost:3002#{label_template_url}")
        .to_raise(JsonApiClient::Errors::ConnectionError)
      stub_request(:post, 'http://localhost:3002/v1/print_jobs')
        .to_raise(JsonApiClient::Errors::ConnectionError)

      pj = PrintJob.new(
        printer_name: printer_pmb.name,
        printer: printer_pmb,
        labels: [
          { label: { barcode: '12345', test_attr: 'test' } }
        ],
        number_of_copies: 1
      )
      expect(pj.execute).to be false
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

    it 'will send a print request to SPrintClient' do
      pj = PrintJob.new(
        printer_name: printer_sprint.name,
        printer: printer_sprint,
        label_templates_by_service: label_templates_by_service,
        labels: [{ label: { barcode: '12345', test_attr: 'test' } }],
        labels_sprint: labels_sprint,
        number_of_copies: 1
      )

      allow(pj).to receive(:get_label_template_by_service).and_return(label_template_name_sprint)
      allow(SPrintClient).to receive(:send_print_request).and_return('a response')
      expect(SPrintClient).to receive(:send_print_request).with(printer_sprint.name, label_template_name_sprint, labels_sprint.values)
      expect(pj.print_to_sprint).to eq(true)
    end
  end
end
