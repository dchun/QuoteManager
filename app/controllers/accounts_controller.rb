class AccountsController < ApplicationController
  skip_before_filter :authenticate_user!, only: [:new, :create, :login]

  def new
    @account = Account.new
    @account.users.build
  end

  def create
    @account = Account.new(account_params)
    if @account.valid?
      @account.save
      redirect_to new_user_session_url
    else
      render action: 'new'
    end
  end

  def login
    @account = current_account
    if @account
      redirect_to new_user_session_url
   else
      redirect_to new_account_path, flash: { 
        :alert => 'Account is invalid. Create an account.' 
      }
   end
  end

private
  def account_params
    params.require(:account).permit(
      :company_name,
      users_attributes: [
        :firstname, 
        :lastname, 
        :email, 
        :password, 
        :password_confirmation
      ]
    )
  end
end
