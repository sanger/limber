# frozen_string_literal: true

module Form # rubocop:todo Style/Documentation
  extend ActiveSupport::Concern

  included do
    include ActiveModel::Model

    class_attribute :page, :aliquot_partial, :attributes, instance_writer: false
    self.page = 'new'
    self.aliquot_partial = 'standard_aliquot'
  end

  def persisted?
    false
  end
end
