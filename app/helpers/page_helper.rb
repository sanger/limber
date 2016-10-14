#This file is part of Illumina-B Pipeline is distributed under the terms of GNU General Public License version 3 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2011,2012 Genome Research Ltd.
module PageHelper

  FLASH_STYLES = {
    'alert'   => 'danger',
    'danger'  => 'danger',
    'notice'  => 'success',
    'success' => 'success',
    'warning' => 'warning',
    'info'    => 'info'
  }.freeze
  DEFAULT_FLASH_STYLE = 'info'


  def flash_messages
    render(:partial => 'labware/flash_messages')
  end

  def grouping(data_role, options = {}, &block)
    content_tag(:div, options, &block)
  end
  private :grouping

  # Renders the content in the block in the
  # standard page template, including heading flash and sidebar
  def page(id, css_class=nil, &block)
    grouping(:page, :id => id, :class => "container-fluid #{css_class}") do
      concat render :partial => 'header'
      concat flash_messages
      concat content_tag(:div, class: 'row', &block)
    end
  ensure
    content_for :header, ''
  end

  def header(presenter = nil, title = nil, options = {}, &block)
    theme = options[:'data-theme'] || data_theme

    content_for(:header, &block) if block_given?
    grouping(:header, 'data-theme' => theme) do
      render(:partial => 'labware/header', :locals => { :presenter => presenter, :title => title })
    end
  end

  # Main body of the page, provides information about what you HAVE
  def content(&block)
    grouping(:content, class: 'col-sm-8 content-main', &block)
  end

  # Provides information about what you can DO
  def sidebar(&block)
    grouping(:sidebar, class: 'col-sm-4 sidebar content-secondary', &block)
  end

  def card(&block)
    content_tag(:div, class: 'card', &block)
  end

  def footer(&block)
    grouping(:footer, 'data-position' => 'fixed') do
      render(:partial => 'labware/footer')
    end
  end

  def section(options = {}, &block)
    # add section to the section's CSS class attribute
    options[:class] = [ options[:class], 'section' ].compact.join(" ")
    content_tag(:div, options, &block)
  end

  def jumbotron(jumbotron_id=nil, options={}, &block)
    options[:class] ||= ''
    options[:class] << ' jumbotron'
    options[:id] = jumbotron_id
    section(options, &block)
  end

  def flash_style(level)
    FLASH_STYLES[level]||DEFAULT_FLASH_STYLE
  end
end
