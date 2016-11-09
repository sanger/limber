# frozen_string_literal: true
# This file is part of Illumina-B Pipeline is distributed under the terms of GNU General Public License version 3 or later;
# Please refer to the LICENSE and README files for information on licensing and authorship of this file.
# Copyright (C) 2011,2012,2013 Genome Research Ltd.
class PlatesController < LabwareController
  module LabwareWrangler
    def locate_labware_identified_by(id)
      api.plate.find(id).coerce.tap(&:populate_wells_with_pool)
    end
  end

  include PlatesController::LabwareWrangler

  before_action :check_for_current_user!, only: [:update, :fail_wells]

  def fail_wells
    wells_to_fail = params[:plate][:wells].select { |_, v| v == '1' }.map(&:first)

    if wells_to_fail.empty?
      redirect_to(limber_plate_path(params[:id]), notice: 'No wells were selected to fail')
    else
      api.state_change.create!(
        user: current_user_uuid,
        target: params[:id],
        contents: wells_to_fail,
        target_state: 'failed',
        reason: 'Individual Well Failure',
        customer_accepts_responsibility: params[:customer_accepts_responsibility]
      )
      redirect_to(limber_plate_path(params[:id]), notice: 'Selected wells have been failed')
    end
  end

  def presenter_for(labware)
    Presenters::PlatePresenter.lookup_for(labware).new(
      api:     api,
      labware: labware
    )
  end
end
