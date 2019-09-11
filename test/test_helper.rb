ENV['RAILS_ENV'] = 'test'
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'minitest/rails'
require 'minitest/pride'

# require 'minitest/reporters'
Minitest::Reporters.use!

class ActionController::TestCase
  include Devise::TestHelpers

  def assert_flash_notice(msg)
    assert_equal msg, flash[:notice]
  end

  def assert_flash_alert(msg)
    assert_equal msg, flash[:alert]
  end

  def assert_new_record_of(cls, obj)
    assert_instance_of cls, obj
    assert obj.new_record?, "Expected #{mu_pp(obj)} to be a new record, but it was not"
  end

end

class ActiveSupport::TestCase
  ActiveRecord::Migration.check_pending!

  # Setup all fixtures in test/fixtures/*.(yml|csv) for all tests in alphabetical order.
  #
  # Note: You'll currently still have to declare fixtures explicitly in integration tests
  # -- they do not yet inherit this setting
  # fixtures :all

  include FactoryGirl::Syntax::Methods

  def date_time_params(name, date = Date.today)
    {
        :"#{name}(1i)" => date.strftime('%Y'), #year
        :"#{name}(2i)" => date.strftime('%-m'), #month
        :"#{name}(3i)" => date.strftime('%d'), #day
        :"#{name}(4i)" => date.strftime('%H'), #hour
        :"#{name}(5i)" => date.strftime('%M'), #minute
        :"#{name}(6i)" => date.strftime('%S')  #second
    }
  end

  def self.it_should_require_user_for(actions, params = {})
    describe 'redirect non-user' do
      actions.each do |action|
        it "#{action} action should redirect to sign in page" do
          get action, params
          assert_redirected_to new_user_session_path
          assert_equal flash[:alert], 'Du skal logge ind for at kunne fortsætte.'
        end
      end
    end
  end

end