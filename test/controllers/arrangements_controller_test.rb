require 'test_helper'

describe ArrangementsController do

  actions = [:new, :create]
  it_should_require_user_for actions, customer_id: 1, department_id: 1

  describe 'forbid user with no permission to department' do
    actions.each do |action|
      it "#{action} action should require permission to department" do
        department       = create(:department)
        other_department = create(:department)
        customer         = create(:customer, department_id: department.id)
        new_user         = create(:user, role: 'default', department_ids: [other_department.id])
        sign_in new_user
        get action, customer_id: customer.id, department_id: department.id, arrangement: { min_scrap: 1 }
        assert_response 403
      end
    end
  end

  describe 'with signed in user' do

    before(:each) do
      @department = create(:department)
      @customer = create(:customer, :department_id => @department.id)
      # NOTE: creating a customer is automaticaly creating an arrangement
      @user = create(:user, :department_ids => [@department.id])
      sign_in @user
    end

    describe 'GET #new' do

      it 'should return http success and render new template with new arrangement' do
        get :new, :customer_id => @customer.id, :department_id => @department.id
        assert_response :success
        assert_template :new
        assert_new_record_of Arrangement, assigns(:arrangement)
      end

      it 'should load data from previous arrangement' do
        # update current arrangement to be older
        @customer.current_arrangement.update(:use_scrap => true, :use_scrap_minimum => true, :scrap_minimum => 99, :created_at => 2.days.ago)
        current = create(:arrangement, :use_scrap_minimum => false, :customer => @customer, :created_at => 1.day.ago)
        get :new, :customer_id => @customer.id, :department_id => @department.id
        refute_equal current, assigns(:arrangement)
        assert_new_record_of Arrangement, assigns(:arrangement)
        assert_equal current.use_scrap, assigns(:arrangement).use_scrap
        assert_equal current.use_scrap_minimum, assigns(:arrangement).use_scrap_minimum
        assert_equal current.scrap_minimum, assigns(:arrangement).scrap_minimum
      end

      it 'should have empty data without previous arrangement' do
        get :new, :customer_id => @customer.id, :department_id => @department.id
        empty = Arrangement.new
        refute_nil assigns(:arrangement)
        assert_equal empty.use_scrap, assigns(:arrangement).use_scrap
        assert_equal empty.use_scrap_minimum, assigns(:arrangement).use_scrap_minimum
        assert_equal empty.scrap_minimum, assigns(:arrangement).scrap_minimum
      end

    end

    describe 'POST #create' do

      it 'should create and redirect to customer with flash' do
        post :create, :customer_id => @customer.id, :department_id => @department.id, :arrangement => {
            :use_scrap => true,
            :use_scrap_minimum => true,
            :scrap_minimum => 45
        }
        refute_nil assigns(:arrangement)
        assert assigns(:arrangement).use_scrap
        assert assigns(:arrangement).use_scrap_minimum
        assert_equal 45, assigns(:arrangement).scrap_minimum
        assert_redirected_to [@department, @customer]
        assert_equal 'Aftalen er nu oprettet.', flash[:notice]
      end

      it 'should get error with use_scrap_minimum == true when setting scrap_minimun to a value under 1 ' do
        post :create, :customer_id => @customer.id, :department_id => @department.id, :arrangement => {
            :use_scrap => true,
            :use_scrap_minimum => true,
            :scrap_minimum => 0
        }
        assert_template :new
        assert_new_record_of Arrangement, assigns(:arrangement)
        assert_includes assigns(:arrangement).errors[:scrap_minimum], 'skal være større end 1'
      end

      it 'should ignore validation for scrap_minimum <= 1 if use_scrap_minimum is false' do
        post :create, :customer_id => @customer.id, :department_id => @department.id, :arrangement => {
            :use_scrap => true,
            :use_scrap_minimum => false,
            :scrap_minimum => 0
        }
        refute_nil assigns(:arrangement)
        assert assigns(:arrangement).use_scrap
        refute assigns(:arrangement).use_scrap_minimum
        assert_nil assigns(:arrangement).scrap_minimum
        assert_redirected_to [@department, @customer]
        assert_equal 'Aftalen er nu oprettet.', flash[:notice]
      end

    end

  end

end