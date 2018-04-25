# frozen_string_literal: true

require 'rails_helper'

describe PrintJob do
  has_a_working_api
  let(:printer) { build :barcode_printer }
  let(:label_template_id) { 1 }
  let(:label_template_name) { 'sqsc_96plate_label_template' }
  let(:label_template_url) { "/v1/label_templates?filter%5Bname%5D=#{label_template_name}&page%5Bnumber%5D=1&page%5Bsize%5D=1" }

  it 'should send post request to pmb if job is valid' do
    PMB::TestSuiteStubs.get(label_template_url) do |_env|
      [
        200,
        { content_type: 'application/json' },
        label_template_response(label_template_id, label_template_name)
      ]
    end

    PMB::TestSuiteStubs.post('/v1/print_jobs', print_job_post(printer.name, label_template_id)) do |_env|
      [
        200,
        { content_type: 'application/json' },
        print_job_response(printer.name, label_template_id)
      ]
    end

    pj = PrintJob.new(
      printer_name: printer.name,
      label_template: label_template_name,
      labels: [{ label: { barcode: '12345', test_attr: 'test' } }],
      number_of_copies: 1
    )
    expect(pj.execute).to be true
  end

  it 'should multiply lablels if several copies required' do
    PMB::TestSuiteStubs.get(label_template_url) do |_env|
      [
        200,
        { content_type: 'application/json' },
        label_template_response(label_template_id, label_template_name)
      ]
    end

    PMB::TestSuiteStubs.post('/v1/print_jobs', print_job_post_multiple_labels(printer.name, label_template_id)) do |_env|
      [
        200,
        { content_type: 'application/json' },
        print_job_response(printer.name, label_template_id)
      ]
    end

    pj = PrintJob.new(
      printer_name: printer.name,
      label_template: label_template_name,
      labels: [
        { label: { barcode: '12345', test_attr: 'test' } },
        { label: { barcode: '67890', test_attr: 'test2' } }
      ],
      number_of_copies: 2
    )
    expect(pj.execute).to be true
  end

  # it 'should not execute if pmb is down' do
  #   stub_request(:get, "http://localhost:3002" + label_template_url)
  #     .to_raise(JsonApiClient::Errors::ConnectionError)
  #   stub_request(:post, "http://localhost:3002/v1/print_jobs")
  #     .to_raise(JsonApiClient::Errors::ConnectionError)
  #   pj = PrintJob.new(printer_name: printer.name, printer_type: printer.type.name, labels:[{label:{barcode:'12345', test_attr:'test'}}], number_of_copies: 1)
  #   expect(pj.execute).to be false
  # end
end
