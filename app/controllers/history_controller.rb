class HistoryController < ApplicationController # rubocop:todo Style/Documentation
  def index
    @steps = Step.order(id: :desc).paginate(page: params[:page], per_page: 10)
  end
end
