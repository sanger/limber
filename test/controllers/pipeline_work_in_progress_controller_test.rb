require "test_helper"

class PipelineWorkInProgressControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get pipeline_work_in_progress_index_url
    assert_response :success
  end
end
