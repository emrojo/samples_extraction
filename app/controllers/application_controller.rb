class ApplicationController < ActionController::Base

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  rescue_from ActiveRecord::RecordNotFound, :with => :record_not_found

  before_action :set_current_user

  attr_reader :current_user

  def record_not_found(exception)
    flash.now[:error] = 'No record found'
    redirect_to :action => 'index'
  end

  def set_current_user
    @current_user = nil
    if session[:token]
      @current_user = User.find_by(:token => session[:token])
      unless @current_user
        # If I am logged in a different host, I lose the session in this one
        session[:token]=nil
      end
    end
  end

end
