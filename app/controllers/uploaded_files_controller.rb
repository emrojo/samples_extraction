class UploadedFilesController < ApplicationController # rubocop:todo Style/Documentation
  before_action :set_uploaded_file, only: [:show]

  def show
    respond_to do |format|
      format.bin { send_data(@uploaded_file.data, filename: @uploaded_file.filename) }
      format.html { render :show }
      format.n3 { render :show }
    end
  end

  private

  def set_uploaded_file
    @uploaded_file = UploadedFile.find(params[:id])
  end
end
