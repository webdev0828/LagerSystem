require 'test_helper'

describe AccountsController do

  actions = [ :index, :show, :new, :create, :destroy, :current, :test, :current_list, :current_list_weight, :list, :list_weight, :summary ]
  it_should_require_user_for actions, :id => 1, :customer_id => 1, :department_id => 1

  describe 'forbid user with no permission to department' do
    actions.each do |action|
      it "#{action} action should require permission to department" do
        @department = create(:department)
        @customer = create(:customer, :department_id => @department.id)
        @interval = create(:interval, :customer_id => @customer.id)
        sign_in create(:user, :role => 'default', :department_ids => [@department.id+1])
        get action, :id => @interval.id, :customer_id => @customer.id, :department_id => @department.id
        assert_response 403
      end
    end
  end

  describe 'with signed in user' do

    before(:each) do
      @department = create(:department)
      @customer = create(:customer, :department_id => @department.id)
      sign_in create(:user, :department_ids => [@department.id])
    end

    describe 'GET #index' do

      before(:each) do
        get :index, :customer_id => @customer.id, :department_id => @customer.department_id
      end

      it 'should return http success' do
        assert_response :success
      end

      it 'should render template index' do
        assert_template :index
      end

    end

    describe 'GET #show' do

      before(:each) do
        @interval = create(:interval, :customer_id => @customer.id)
        get :show, :id => @interval.id, :customer_id => @customer.id, :department_id => @customer.department_id
      end

      it 'should return http success' do
        assert_response :success
      end

      it 'should render template show' do
        assert_template :show
      end

      it 'should show notes since last interval'

    end

    describe 'GET #new' do

      before(:each) do
        get :new, :customer_id => @customer.id, :department_id => @customer.department_id
      end

      it 'should return http success' do
        assert_response :success
      end

      it 'should render template new' do
        assert_template :new
      end

    end

    describe 'POST #create' do

      it 'should require :from parameter when creating first interval' do
        post :create, {
            :interval => date_time_params(:to, Time.now),
            :customer_id => @customer.id,
            :department_id => @customer.department_id
        }
        assert_response :success
        assert_template :new
        refute assigns(:interval).valid?
        assert_equal ['skal udfyldes'], assigns(:interval).errors[:from]
      end

      it 'should return http redirect' do
        # create pre existing interval
        create(:interval, :to => 1.week.ago, :customer_id => @customer.id)
        post :create, {
            :interval => date_time_params(:to, 0.seconds.ago),
            :customer_id => @customer.id,
            :department_id => @customer.department_id
        }
        refute_nil assigns(:interval)
        assert_empty assigns(:interval).errors
        assert_redirected_to [@department, @customer, assigns(:interval)]
      end

    end

    describe 'DELETE #destroy' do

      it 'should reject deleting if interval is not the latest one'

      it 'should succeed in deleting newest interval'

    end

    it 'GET #current'

    it 'GET #test'

    it 'GET #current_list'

    it 'GET #current_list_weight'

    it 'GET #list'

    it 'GET #list_weight'

    it 'GET #summary'

  end

end
