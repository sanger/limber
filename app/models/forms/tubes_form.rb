#This file is part of Illumina-B Pipeline is distributed under the terms of GNU General Public License version 3 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2011,2012 Genome Research Ltd.
module Forms
  class TubesForm < CreationForm

    def render(controller)
      if no_pooling_required?
        super
      else
        controller.render(self.page)
      end
    end

    attr_reader :all_tube_transfers

    def no_pooling_required?
      false
    end

    write_inheritable_attribute :page, 'multi_tube_pooling'
    write_inheritable_attribute :attributes, [:api, :purpose_uuid, :parent_uuid, :user_uuid, :parents]

    validate :all_barcodes_found?, :if => :barcodes_provided?

    def create_objects!
      success = []
      @all_tube_transfers = parents.map do |this_parent_uuid|
        transfer_template.create!(
          :user   => user_uuid,
          :source => this_parent_uuid
        ).tap { success << this_parent_uuid }
      end
      true
    rescue => e
      errors.add(:base,"#{success.count} tubes were transferred successfully before something went wrong." )
      errors.add(:base,exception.message)
      false
    end

    # We pretend that we've added a new blank tube when we're actually
    # transfering to the tube on the original LibraryRequest
    def child
      return :contents_not_transfered_to_mx_tube if all_tube_transfers.nil?
      destination_uuids = all_tube_transfers.map do |tt|
        tt.destination.uuid
      end.uniq
      return all_tube_transfers.first.destination if destination_uuids.one?
      raise StandardError, 'Multiple targets found. You may have scanned tubes from separate submissions.'
    end

    def parents=(barcode_hash)
      return unless barcode_hash.respond_to?(:keys)
      @expected_parents_count = barcode_hash.keys.count
      results = api.search.find(Settings.searches['Find assets by barcode']).all(Sequencescape::Tube,:barcode => barcode_hash.keys)
      @parents = results.map(&:uuid)
    end

    def parents
      @parents || [ parent_uuid ]
    end

    private

    def barcodes_provided?
      @expected_parents_count.present?
    end

    def all_barcodes_found?
      return true if @parents.count == @expected_parents_count
      errors.add(:base,"Could only find #{@parents.count} of the #{@expected_parents_count} barcodes")
      false
    end

    def transfer_template
      @template ||= api.transfer_template.find(
        Settings.transfer_templates["Transfer from tube to tube by submission"]
      )
    end

  end
end
