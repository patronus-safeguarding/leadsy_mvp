class SettingsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user

  def show
    # Display current settings
  end

  def edit
    # Show edit form
  end

  def update
    if @user.update(user_params)
      redirect_to settings_path, notice: 'Settings updated successfully.'
    else
      render :edit
    end
  end

  private

  def set_user
    @user = current_user
  end

  def user_params
    params.require(:user).permit(:first_name, :last_name, :email, :agency_name, :logo)
  end
end
