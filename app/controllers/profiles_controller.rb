class ProfilesController < ApplicationController
  before_filter :require_user, :load_user

  def edit
  end

  def update
    if @user.update_attributes(params[:user])
      flash[:notice] = 'Profile was successfully updated'
      redirect_to root_url
    else
      flash.now[:error] = "Oops, we couldn't save your changes."
      render :action => 'edit'
    end
  end

  def disable_tips
    @user.tips_shown = false
    @user.save
    render :nothing => true
  end

  private
    def load_user
      @user = current_user
    end
end
