class ApplicationController < ActionController::Base
  protect_from_forgery

  before_filter :authenticate_user!
  layout :layout

  check_authorization :unless => :devise_controller?
  rescue_from CanCan::AccessDenied do |exception|
    respond_to do |format|
      format.html { render :file => "#{Rails.root}/public/403", :status => 403, :layout => false, :formats => [:html] }
      format.any  { head 403 }
    end
  end

  protected

  def send_as_file(type, filename)
    self.content_type = Mime[type]
    headers.merge!(
      'Content-Disposition'       => %(attachment; filename="#{filename}"),
      'Content-Transfer-Encoding' => 'binary'
    )
    response.sending_file = true
    response.cache_control[:public] ||= false
  end

  # Devise callback for redirecting after user sign in
  def user_root_path
    if current_user and current_user.department_ids.size == 1
      "/departments/#{current_user.department_ids.first}/customers"
    else
      root_path
    end
  end

  private

  def layout
    devise_controller? ? 'simple' : 'application'
  end

  # Devise callback for redirecting after sign out
  def after_sign_out_path_for(_)
    new_user_session_path
  end

end
