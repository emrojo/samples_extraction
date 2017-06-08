class HistoryController < ApplicationController
  def index
    @steps = Step.for_history.paginate(:page => params[:page], :per_page => 5)
  end
end
