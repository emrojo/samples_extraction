class UserSessionsController < ApplicationController # rubocop:todo Style/Documentation
  before_action :set_user, only: [:create]

  def create
    session[:token] = @user.generate_token
  end

  def destroy
    @current_user.clean_session if @current_user
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
