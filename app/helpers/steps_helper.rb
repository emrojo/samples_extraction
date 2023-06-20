module StepsHelper # rubocop:todo Style/Documentation
  def text_color_for_state(state)
    "text-#{color_for_state(state)}"
  end

  def color_for_state(state)
    css = 'primary'
    css = 'success' if state == 'complete'
    css = 'danger' if state == 'error'
    css = 'warning' if state == 'running'
    css = 'danger' if state == 'cancel'
    css = 'info' if state == 'in progress'

    return css
  end

  def image_for_state(state)
    css = 'glyphicon-ok' if state == 'complete'
    css = 'glyphicon-remove' if state == 'error'
    css = 'glyphicon-refresh fast-right-spinner' if state == 'running'
    css = 'glyphicon-repeat' if state == 'in progress'
    css = 'glyphicon-erase' if state == 'cancel'

    return "<span class='glyphicon #{css} #{text_color_for_state(state)}'></span>".html_safe
  end
end
