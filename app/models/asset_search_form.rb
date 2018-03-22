# frozen_string_literal: true

# Simple class to handle form input for searching
class AssetSearchForm
  PER_PAGE = 30
  MAX_TABS = 10

  include ActiveModel::Model
  # We include 'show_my_plates_only' to let us share pagination forms
  attr_accessor :show_my_plates_only, :include_used, :states, :total_results
  attr_writer :purposes, :page

  class_attribute :form_partial

  def to_partial_path
    "search/#{form_partial}"
  end

  def purpose_uuids
    purposes.presence || default_purposes
  end

  def purposes
    @purposes || []
  end

  def page
    @page || 1
  end

  def total_pages
    @total_page ||= (total_results || 0) / PER_PAGE
  end

  def each_page
    1.upto(total_pages) do |page_number|
      next if filter(page_number)
      yield page_number, page == page_number
    end
  end

  def filter(number)
    return false if total_pages < MAX_TABS
    return false if [1, total_pages].include?(number)
    (page - number).magnitude > MAX_TABS / 2
  end
end
