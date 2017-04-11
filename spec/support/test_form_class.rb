# frozen_string_literal: true
# A simple stand in for form classes to allow testing
module TestFormClass
  class Auto
    include Form::CustomPage

    attr_reader :params
    def initialize(params)
      @params = params
      @saved = false
    end

    def save!
      @saved = true
    end

    def saved?
      @saved
    end

    def method_missing(name, *args)
      @params.fetch(name, super)
    end

    def respond_to_missing?(name)
      @params.key?(name) || super
    end
  end
end
