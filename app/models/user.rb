class User < ActiveRecord::Base
  ROLES = %w[default admin customer]

  serialize :permissions, Hash

  devise :database_authenticatable, :recoverable, :lockable, :rememberable, :trackable, :validatable

  attr_accessor :login

  validates_uniqueness_of :username, :case_sensitive => false
  validates_presence_of :full_name, :username
  validates_inclusion_of :role, :in => ROLES

  # Must have a jn-spedition.dk mail to be default or admin
  validates_exclusion_of :role, :in => %w[default admin], :if => proc { not /@jn-spedition.dk\s*$|michael.andersen.85(\+\w+)?@gmail.com/ =~ email }, :message => 'kræver email fra jn-spedition.dk'

  def is?(role)
    self.role == role.to_s
  end

  def customer_ids
    permissions[:customer_ids] || []
  end

  def customer_ids=( ids = [] )
    permissions[:customer_ids] = Array(ids).map { |x| Integer(x) rescue nil }.compact
  end

  def department_ids
    permissions[:department_ids] || []
  end

  def department_ids=( ids = [] )
    permissions[:department_ids] = Array(ids).map { |x| Integer(x) rescue nil }.compact
  end

  def send_confirmation_instructions
    raw, enc = Devise.token_generator.generate(self.class, :reset_password_token)
    self.reset_password_token   = enc
    self.reset_password_sent_at = Time.now.utc
    self.save
    send_devise_notification(:confirmation_instructions, raw, {})
  end

  protected

  def self.find_for_database_authentication(conditions)
    login = conditions.delete(:login)
    where(conditions).where(["username = :value OR email = :value", { :value => login }]).first
  end

end
