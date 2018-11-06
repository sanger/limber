# frozen_string_literal: true

module PageHelper
  def flash_messages
    render(partial: 'application/flash_messages')
  end

  def grouping(_data_role, options = {}, &block)
    content_tag(:div, options, &block)
  end
  private :grouping

  # Renders the content in the block in the
  # standard page template, including heading flash and sidebar
  def page(id, css_class = nil, prevent_row: false, &block)
    grouping(:page, id: id, class: "container-fluid #{css_class}") do
      if prevent_row
        concat yield
      else
        concat content_tag(:div, class: 'row', &block)
      end
    end
  end

  # Main body of the page, provides information about what you HAVE
  def content(&block)
    grouping(:content, class: 'content-main', &block)
  end

  # Provides information about what you can DO
  def sidebar(&block)
    grouping(:sidebar, class: 'sidebar content-secondary', &block)
  end

  def card(title: nil, css_class: '', without_block: false, id: nil, &block)
    content_tag(:div, class: "card #{css_class}", id: id) do
      concat content_tag(:h3, title, class: 'card-header') if title
      if without_block
        yield
      else
        concat content_tag(:div, class: 'card-body', &block)
      end
    end
  end

  def jumbotron(jumbotron_id = nil, options = {}, &block)
    options[:class] ||= +''
    options[:class] << ' jumbotron'
    options[:id] = jumbotron_id
    content_tag(:div, options, &block)
  end

  # eg. state_badge('pending')
  # <span class="state-badge-pending">Pending</span>
  def state_badge(state)
    content_tag(:span, state.titleize, class: "state-badge #{state}")
  end
end
