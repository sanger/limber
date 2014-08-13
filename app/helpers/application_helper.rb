module ApplicationHelper

  def environment
    Rails.env
  end

  def non_production_class
    Rails.env != 'production' ? 'nonproduction' : ''
  end

  def custom_theme
    yield 'nonproduction' unless Rails.env == 'production'
  end
end
