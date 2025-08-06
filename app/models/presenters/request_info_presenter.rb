# frozen_string_literal: true

class Presenters::RequestInfoPresenter
  attr_reader :labware

  # redirect presenter methods to the labware
  delegate :uuid, to: :labware

  # Initializes the presenter with the given labware.
  #
  # @param labware [Labware] The labware item to present.
  def initialize(labware)
    @labware = labware
  end

  delegate :active_requests, to: :@labware

  def grouped_active_requests(by: %i[name state])
    active_requests.group_by do |request|
      by.map do |attr|
        request.send(attr)
      rescue NoMethodError
        request.request_type.send(attr)
      end
    end
      .transform_values(&:size)
  end

  # Returns a string of the active request types and their class names.
  def active_request_info
    grouped_active_request.inspect
    # active_requests.map do |request|
    #   "#{request.request_type.name} (#{
    #     request.request_type.inspect
    #   })"
    # end.uniq.join(', ')
  end

  # # Returns the number of active requests.
  # def request_count
  #   active_requests.size
  # end
end
