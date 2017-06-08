# frozen_string_literal: true
class UserSessionsController < ApplicationController
  before_filter :set_user, only: :create

  def create
    session[:token] = @user.generate_token
  end

  def destroy
    @current_user.clean_session
    session[:token] = nil

    head :no_content
  end

  private

  def user_session_params
    params.require(:user_session).permit(:barcode, :token)
  end

  def set_user
    @user = User.find_by!(barcode: user_session_params[:barcode])
  end
end
