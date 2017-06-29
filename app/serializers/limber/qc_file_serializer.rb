# frozen_string_literal: true

class Limber::QcFileSerializer < ActiveModel::Serializer
  attributes :uuid, :filename, :size
end
