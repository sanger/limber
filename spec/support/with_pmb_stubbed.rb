# frozen_string_literal: true

require 'rails_helper'

PMB::TestSuiteStubs = Faraday::Adapter::Test::Stubs.new
PMB::Base.connection.delete(Faraday::Adapter::NetHttp)
PMB::Base.connection.faraday.adapter :test, PMB::TestSuiteStubs

def print_job_response(printer_name, template_id)
  %({
    "data": {
      "id": "",
      "type": "print_jobs",
      "attributes": {
        "printer_name": "#{printer_name}",
        "label_template_id": #{template_id},
        "labels": {
          "body": [
            {
              "label": {
                "barcode":"12345",
                "test_attr":"test"
              }
            }
          ]
        }
      }
    }
  })
end

def print_job_post(printer_name, template_id)
  {
    data: {
      type: 'print_jobs',
      attributes: {
        printer_name: printer_name,
        label_template_id: template_id,
        labels: {
          body: [
            { label: { barcode: '12345', test_attr: 'test' } }
          ]
        }
      }
    }
  }.to_json
end

def print_job_post_multiple_labels(printer_name, template_id)
  {
    data: {
      type: 'print_jobs',
      attributes: {
        printer_name: printer_name,
        label_template_id: template_id,
        labels: {
          body: [
            { label: { barcode: '12345', test_attr: 'test' } },
            { label: { barcode: '67890', test_attr: 'test2' } },
            { label: { barcode: '12345', test_attr: 'test' } },
            { label: { barcode: '67890', test_attr: 'test2' } }
          ]
        }
      }
    }
  }.to_json
end

def label_template_response(id, name)
  %({
    "data":
      [
        {
          "id": #{id},
          "type": "label_templates",
          "attributes": {
            "name": "#{name}"
          }
        }
      ]
  })
end
