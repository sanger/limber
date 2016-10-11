module StateChangers
  class MiSeqQcTubeStateChanger < StateChangers::DefaultStateChanger

    REQUEST_GENERATION_STEP = 'passed'

    class SubmissionFailure < StandardError; end

    def move_to!(state, reason = nil, customer_accepts_responsibility = false)
      super
      generate_submissions! if state == REQUEST_GENERATION_STEP
    end

    private

    def generate_submissions!
      begin
        order = api.order_template.find(Settings.submission_templates.miseq).orders.create!(
          :study => Settings.study,
          :project => Settings.project,
          :assets => [labware_uuid],
          :request_options => Limber::Application.config.request_options,
          :user => user_uuid
        )


        submission = api.submission.create!(
          :orders => [order.uuid],
          :user => user_uuid
        )

        submission.submit!

      rescue Sequencescape::Api::ConnectionFactory::Actions::ServerError => exception
        raise SubmissionFailure, ('Submission Failed. ' + /.+\[([^\]]+)\]/.match(exception.message)[1])
      rescue Sequencescape::Api::ResourceInvalid => exception
        raise SubmissionFailure, ('Submission Failed. ' + exception.resource.errors.full_messages.join('; '))
      end
    end

  end
end
