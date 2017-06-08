# frozen_string_literal: true
module StepsHelper
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

    css
  end

  def image_for_state(state)
    css = 'glyphicon-ok' if state == 'complete'
    css = 'glyphicon-remove' if state == 'error'
    css = 'glyphicon-refresh fast-right-spinner' if state == 'running'
    css = 'glyphicon-repeat' if state == 'in progress'
    css = 'glyphicon-erase' if state == 'cancel'

    "<span class='glyphicon #{css} #{text_color_for_state(state)}'></span>".html_safe
  end
end
