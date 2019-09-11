class UsersController < ApplicationController
  load_and_authorize_resource
  before_filter :load_department_labels, :only => [:index, :show]
  before_filter :set_random_password, :only => :create

  def index
    @groups = @users.group_by(&:role)

    @customer_labels = Customer.active.all.inject({}) { |h,c| h[c.id] = c.name + ' (' + c.department.label + ')'; h }
    @department_labels = Department.all.inject({}) { |h,d| h[d.id] = d.label; h }
  end

  def show
    @customer_groups = Customer.active.includes(:department).order(:department_id, :position).group_by(&:department)
  end

  def create
    if @user.save
      redirect_to @user, :notice => 'Brugeren er nu oprettet.'
    else
      render :action => "new"
    end
  end

  def update
    if current_user == @user && user_params[:role] != 'admin'
      @user.errors.add(:role, 'Du kan ikke sætte din egen bruger til "standard"')
      render :action => 'edit'
    elsif @user.update_attributes(user_params)
      redirect_to @user, :notice => 'Brugeren er nu opdateret.'
    else
      render :action => "edit"
    end
  end

  def destroy
    if current_user != @user
      @user.destroy
      redirect_to :users
    else
      redirect_to @user, :alert => 'Du kan ikke slette din egen bruger'
    end
  end

  def mail
    @user.send_confirmation_instructions
    redirect_to @user, :notice => 'Der er nu sent en velkomstmail.'
  end

  def toggle_customer
    @customer = Customer.active.find(params[:customer_id].to_i)
    customer_ids = @user.customer_ids
    deleted = customer_ids.delete(@customer.id)
    customer_ids << @customer.id if deleted.nil?
    @user.customer_ids = customer_ids
    @user.save
    render :action => 'toggle'
  end

  def toggle_department
    @department = Department.find(params[:department_id].to_i)
    department_ids = @user.department_ids
    deleted = department_ids.delete(@department.id)
    department_ids << @department.id if deleted.nil?
    @user.department_ids = department_ids
    @user.save
    render :action => 'toggle'
  end

  def lock
    if @user == current_user
      redirect_to @user, :alert => 'Du kan ikke deaktivere din egen bruger'
    else
      @user.lock_access!
      redirect_to @user, :notice => 'Brugeren er nu deaktiveret.'
    end
  end

  def unlock
    @user.unlock_access!
    redirect_to @user, :notice => 'Brugeren er nu aktiveret.'
  end

  def become
    if current_user.is? :admin
      sign_in :user, @user
      redirect_to (@user.is?(:customer) ? customer_root_path : root_path), notice: "Du er nu logget ind som #{@user.full_name}"
    else
      redirect_to users_path, alert: 'Der skete en ukendt fejl. Kontakt en (anden) administrator.'
    end
  end

  private

  def load_department_labels
    @department_labels = {}
    Department.all.each do |department|
      @department_labels[department.id] = department.label
    end
  end

  def set_random_password
    @user.password = @user.password_confirmation = Devise.friendly_token
  end

  def user_params
    params.require(:user).permit(:email, :username, :full_name, :phone, :role, :department_ids => [])
  end

end
