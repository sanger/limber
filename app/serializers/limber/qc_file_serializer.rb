class Limber::QcFileSerializer < ActiveModel::Serializer
  attributes :uuid, :filename, :size
end
