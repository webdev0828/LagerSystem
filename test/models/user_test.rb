require 'test_helper'

describe User do

  before(:each) do
    @attr = attributes_for :user
  end

  it 'should create a new instance given a valid attribute' do
    User.create!(@attr)
  end

  it 'should require an email address' do
    user = User.new(@attr.merge(:email => ''))
    refute user.valid?
  end

  describe 'as default role' do

    it 'should require default users email to end with @jn-spedition.dk' do
      user = User.new(attributes_for :user, email: 'some-users-name@jn-spedition.dk')
      assert user.valid?
    end

    it 'should reject when default users email ends with something else than @jn-spedition.dk' do
      user = User.new(attributes_for :user, email: 'some-users-name@other.dk')
      refute user.valid?
    end

  end

  it 'should accept valid email addresses' do
    addresses = %w[user@jn-spedition.dk THE_USER@foo.bar.org first.last@foo.jp]
    addresses.each do |address|
      user = User.new(attributes_for :user, email: address, role: 'customer')
      assert user.valid?
    end
  end

  it 'should reject invalid email addresses' do
    addresses = %w[user@foo,com user_at_foo.org example.user@foo.]
    addresses.each do |address|
      invalid_email_user = User.new(@attr.merge(:email => address))
      refute invalid_email_user.valid?
    end
  end

  it 'should reject duplicate email addresses' do
    User.create!(@attr)
    user_with_duplicate_email = User.new(@attr)
    refute user_with_duplicate_email.valid?
  end

  it 'should reject email addresses identical up to case' do
    email = @attr[:email].upcase
    create :user, email: email
    user = build :user, email: email
    refute user.valid?
  end

  describe 'passwords' do

    before(:each) do
      @user = User.new(@attr)
    end

    it 'should have a password attribute' do
      assert_respond_to @user, :password
    end

    it 'should have a password confirmation attribute' do
      assert_respond_to @user, :password_confirmation
    end
  end

  describe 'password validations' do

    it 'should require a password' do
      new_user = User.new(@attr.merge(:password => '', :password_confirmation => ''))
      refute new_user.valid?
    end

    it 'should require a matching password confirmation' do
      new_user = User.new(@attr.merge(:password_confirmation => 'invalid'))
      refute new_user.valid?
    end

    it 'should reject short passwords' do
      short = 'a' * 5
      new_user = User.new(@attr.merge(:password => short, :password_confirmation => short))
      refute new_user.valid?
    end

  end

  describe 'password encryption' do

    before(:each) do
      @user = User.create!(@attr)
    end

    it 'should have a present encrypted password attribute' do
      assert_respond_to @user, :encrypted_password
      assert @user.encrypted_password.present?
    end

  end

end
