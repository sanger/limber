# frozen_string_literal: true

module PageHelper # rubocop:todo Style/Documentation
  def flash_messages
    render(partial: 'application/flash_messages')
  end

  def grouping(_data_role, options = {}, &)
    tag.div(**options, &)
  end
  private :grouping

  # Renders the content in the block in the
  # standard page template, including heading flash and sidebar
  def page(id, css_class = nil, prevent_row: false, &block)
    grouping(:page, id: id, class: "container-fluid #{css_class}") do
      if prevent_row
        concat yield
      else
        concat tag.div(class: 'row', &block)
      end
    end
  end

  # Main body of the page, provides information about what you HAVE
  def content(&)
    grouping(:content, class: 'content-main', &)
  end

  # Provides information about what you can DO
  def sidebar(&)
    grouping(:sidebar, class: 'sidebar content-secondary', &)
  end

  def card(title: nil, css_class: '', without_block: false, id: nil, &block)
    tag.div(class: "card #{css_class}", id: id) do
      concat tag.h3(title, class: 'card-header') if title
      if without_block
        yield
      else
        concat tag.div(class: 'card-body', &block)
      end
    end
  end

  def jumbotron(jumbotron_id = nil, options = {}, &)
    options[:class] ||= +''
    options[:class] << ' jumbotron'
    options[:id] = jumbotron_id
    tag.div(**options, &)
  end

  # eg. state_badge('pending')
  # <span class="state-badge-pending">Pending</span>
  def state_badge(state, title: 'Labware State')
    tag.span(state.titleize, class: "state-badge #{state}", title: title, data: { 'bs-toggle': 'tooltip' })
  end

  # eg. count_badge(0)
  # <span class="badge bg-secondary">0</span>
  # eg. count_badge(10)
  # <span class="badge bg-primary">10</span>
  def count_badge(count, badge_id = nil, data_attributes = {})
    state =
      case count
      when nil, 0
        'secondary'
      else
        'primary'
      end
    tag.span(count || '...', class: "badge rounded-pill badge-#{state}", id: badge_id, data: data_attributes)
  end
end
