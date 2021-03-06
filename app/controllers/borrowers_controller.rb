class BorrowersController < ApplicationController
  before_action :set_borrower, only: [:show]

  def new
    @user = User.new
  end

  def create
    user = User.new(borrower_params.merge(role: "borrower"))
    if user.save
      session[:user_id] = user.id
      flash[:notice] = "You've been saved"
      redirect_to borrower_path(user)
    else
      flash[:error] = "Something went wrong. Please try again"
      render partial: "borrowers/new"
    end
  end

  def show
    @loan_requests = LoanRequest.where(user_id: params[:id])
    @categories = Category.pluck(:title, :id)
  end

  private

  def borrower_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation)
  end

  def set_borrower
    @borrower = User.find(params[:id])
  end

  def this_borrower?
    current_user && current_user.borrower? && current_user.id == params[:id].to_i
  end

  helper_method :this_borrower?
end
