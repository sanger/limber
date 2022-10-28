# frozen_string_literal: true

require 'rails_helper'
require './app/controllers/print_jobs_controller'

RSpec.describe PrintJobsController, type: :controller do
  describe '#create' do
    has_a_working_api

    it 'creates print_job is successful' do
      stub_api_get('barcode_printers', body: json(:barcode_printer_collection))

      params = {
        print_job: {
          printer_name: 'tube printer 1',
          label_templates_by_service: 'tube_label_template_1d',
          labels: [{ 'label' => { 'barcode' => '12345', 'test_attr' => 'test' } }],
          labels_sprint: {
            sprint: {
              'extra_right_text' => 'some x right text',
              'extra_left_text' => 'some x left text'
            }
          },
          number_of_copies: 1
        }
      }

      print_job_mock = PrintJob.new
      allow(PrintJob).to receive(:new).and_return(print_job_mock)
      allow(print_job_mock).to receive(:execute).and_return(true)

      post :create, params: params, format: :json

      assert assigns(:print_job)
      assert_equal 'Your label(s) have been sent to tube printer 1', flash.notice
    end
  end
end
