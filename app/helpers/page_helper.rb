module PageHelper
  def flash_messages
    render(:partial => 'lab_ware/flash_messages') unless flash.empty?
  end

  def grouping(data_role, options = {}, &block)
    content_tag(:div, options.merge('data-role' => data_role), &block)
  end
  private :grouping

  def page(id, &block)
    grouping(:page, :id => id, &block)
  ensure
    @_content_for[:header] = ''
  end

  def header(presenter = nil, title = nil, options = {}, &block)
    theme = options[:'data-theme'] || data_theme

    content_for(:header, &block) if block_given?
    grouping(:header, 'data-theme' => theme) do
      render(:partial => 'lab_ware/header', :locals => { :presenter => presenter, :title => title })
    end
  end

  # If the user is logged in then use the nice blue theme...
  def data_theme
    current_user_uuid.present? ? 'b' : 'a'
  end

  def content(&block)
    grouping(:content, &block)
  end

  def footer(&block)
    grouping(:footer, 'data-position' => 'fixed') do
      render(:partial => 'lab_ware/footer')
    end
  end

  def section(options = {}, &block)
    # add section to the section's CSS class attribute
    options[:class] = [ options[:class], 'section' ].compact.join(" ")
    content_tag(:div, options, &block)
  end
end
