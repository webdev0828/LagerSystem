class MeController < ApplicationController
  skip_authorization_check

  def edit
    @user = current_user
  end

  def update
    @user = User.find(current_user.id)
    if @user.update_with_password user_params
      redirect_to user_root_path, :notice => 'Din bruger er nu opdateret.'
    else
      @user.clean_up_passwords
      render :action => :edit
    end
  end

  private

  def user_params
    params.require(:user).permit(:current_password, :username, :full_name, :phone, :email, :password, :password_confirmation)
  end

end
