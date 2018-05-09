# frozen_string_literal: true

require 'rails_helper'
require './app/controllers/print_jobs_controller'

describe PrintJobsController, type: :controller do
  describe 'CREATE' do
    has_a_working_api

    let(:label_template_id) { 1 }
    let(:label_template_name) { 'limber_tube_label_template' }
    let(:expected_labels) { [{ 'label' => { 'test_attr' => 'test', 'barcode' => '12345' } }] }

    setup do
      PMB::TestSuiteStubs.get(
        '/v1/label_templates?filter%5Bname%5D=limber_tube_label_template&page%5Bnumber%5D=1&page%5Bsize%5D=1'
      ) do
        [
          200,
          { content_type: 'application/json' },
          label_template_response(label_template_id, label_template_name)
        ]
      end
      PMB::TestSuiteStubs.post(
        '/v1/print_jobs',
        print_job_post('tube_printer', label_template_id)
      ) do
        [
          200,
          { content_type: 'application/json' },
          print_job_response('tube_printer', label_template_id)
        ]
      end
    end

    it 'creates print_job' do
      request.env['HTTP_REFERER'] = root_path

      post :create, params: { print_job: { printer_name: 'tube_printer', label_template: 'limber_tube_label_template',
                                           labels: [{ 'label' => { 'test_attr' => 'test', 'barcode' => '12345' } }],
                                           number_of_copies: 1 } },
                    format: :json
      assert assigns(:print_job)
      assert_equal expected_labels, assigns(:print_job).labels
      assert_equal 'Your label(s) have been sent to tube_printer', flash.notice
    end
  end
end
