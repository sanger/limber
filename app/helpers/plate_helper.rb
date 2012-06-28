module PlateHelper
  class WellFailingPresenter < BasicObject
    def initialize(form, presenter)
      @form, @presenter = form, presenter
    end

    def respond_to?(name, include_private = false)
      super or @presenter.respond_to?(name, include_private)
    end

    def method_missing(name, *args, &block)
      @presenter.send(name, *args, &block)
    end
    protected :method_missing

    def aliquot_partial
      'well_failing_aliquot'
    end

    def form
      @form
    end
  end

  def fail_wells_presenter_from(form, presenter)
    WellFailingPresenter.new(form, presenter)
  end

  def insert_size_class(pool)
    (pool['insert_size']['from'] > Settings.large_insert_limit) ? 'large-insert-size' : ''
  end
end
