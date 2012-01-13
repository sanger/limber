# This is a quick fix since the change in the API to pull the wells out of the plate JSON.
# This application can cache the results of any has_many#all calls.
class Sequencescape::Api::Associations::HasMany::AssociationProxy
  module CacheResults
    def all
      @all ||= super
    end
  end

  include CacheResults
end
