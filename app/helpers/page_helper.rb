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

  STATE_STYLES = {
    'pending'     => 'default',
    'started'     => 'info',
    'passed'      => 'success',
    'qc_complete' => 'primary',
    'cancelled'   => 'danger'
  }.freeze
  DEFAULT_STATE_STYLE = 'default'

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
    grouping(:content, class: 'col-sm-12 col-md-8 col-lg-7 col-xl-6 content-main', &block)
  end

  # Provides information about what you can DO
  def sidebar(&block)
    grouping(:sidebar, class: 'col-sm-12 col-md-4 col-lg-5 col-xl-6 sidebar content-secondary', &block)
  end

  def card(title: nil, without_block: false, &block)
    content_tag(:div, class: 'card') do
      concat content_tag(:h3, title, class: 'card-header') if title
      if without_block
        yield
      else
        concat content_tag(:div, class: 'card-block',&block)
      end
    end
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

  def state_style(state)
    STATE_STYLES[state]||DEFAULT_STATE_STYLE
  end
end
