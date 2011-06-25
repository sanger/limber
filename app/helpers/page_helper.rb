module PageHelper
  def container(data_role, options = {}, &block)
    content_tag(:div, options.merge('data-role' => data_role), &block)
  end
  private :container

  def page(id, &block)
    container(:page, :id => id, &block)
  ensure
    @_content_for[:header] = ''
  end

  def header(&block)
    content_for(:header, &block)
    container(:header, 'data-theme' => 'b') do
      render(:partial => 'lab_ware/header')
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
