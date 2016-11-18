require 'rails_helper'

describe PrintJob do

  has_a_working_api
  let(:printer) { build :printer }
  let(:label_template_id) {1}
  let(:label_template_name) {"sqsc_96plate_label_template"}

  it 'should send post request to pmb if job is valid' do

    PMB::TestSuiteStubs.get("/v1/label_templates?filter%5Bname%5D=#{label_template_name}&page%5Bnumber%5D=1&page%5Bsize%5D=1") { |env| [200, {content_type:'application/json' }, label_template_response(label_template_id, label_template_name)]}
    PMB::TestSuiteStubs.post('/v1/print_jobs', print_job_post(printer.name, label_template_id)) { |env| [200, {content_type:'application/json' }, print_job_response(printer.name, label_template_id)]}
    pj = PrintJob.new(printer_name: printer.name, printer_type: printer.type.layout, labels:[{label:{barcode:'12345', test_attr:'test'}}], number_of_copies: 1)
    expect(pj.execute).to be true

  end

  it 'should multiply lablels if several copies required' do

    PMB::TestSuiteStubs.get("/v1/label_templates?filter%5Bname%5D=#{label_template_name}&page%5Bnumber%5D=1&page%5Bsize%5D=1") { |env| [200, {content_type:'application/json' }, label_template_response(label_template_id, label_template_name)]}
    PMB::TestSuiteStubs.post('/v1/print_jobs', print_job_post_multiple_labels(printer.name, label_template_id)) { |env| [200, {content_type:'application/json' }, print_job_response(printer.name, label_template_id)]}
    pj = PrintJob.new(printer_name: printer.name, printer_type: printer.type.layout, labels:[{label:{barcode:'12345', test_attr:'test'}}, {label:{barcode:'67890', test_attr:'test2'}}], number_of_copies: 2)
    expect(pj.execute).to be true

  end

end

