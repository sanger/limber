module PageHelper
  def flash_messages
    render(:partial => 'lab_ware/flash_messages') unless flash.empty?
  end

  def container(data_role, options = {}, &block)
    content_tag(:div, options.merge('data-role' => data_role), &block)
  end
  private :container

  def page(id, &block)
    container(:page, :id => id, &block)
  ensure
    @_content_for[:header] = ''
  end

  def header(presenter = nil, title = nil, &block)
    content_for(:header, &block) if block_given?
    container(:header, 'data-theme' => 'b') do
      render(:partial => 'lab_ware/header', :locals => { :presenter => presenter, :title => title })
    end
  end

  def content(&block)
    container(:content, &block)
  end

  def footer(&block)
    container(:footer, 'data-position' => 'fixed') do
      render(:partial => 'lab_ware/footer')
    end
  end

  def section(options = {}, &block)
    content_tag(:div, options.merge(:class => 'section'), &block)
  end
end
