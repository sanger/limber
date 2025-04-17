# frozen_string_literal: true

# Source: https://mattbrictson.com/blog/easier-nested-layouts-in-rails#a-nicer-helper-based-approach
module LayoutsHelper
  def parent_layout(layout)
    @view_flow.set(:layout, output_buffer)
    output = render(template: "layouts/#{layout}")
    self.output_buffer = ActionView::OutputBuffer.new(output)
  end
end
