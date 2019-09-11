require 'test_helper'

describe CustomersController do

  actions = [ :index, :show, :new, :create, :edit, :update, :sort ]
  it_should_require_user_for actions, :id => 1, :department_id => 1

  describe 'forbid user with no permission to department' do

    before(:each) do
      @department = create(:department)
      @customer = create(:customer, :department_id => @department.id)
      sign_in create(:user, :role => 'default', :department_ids => [@department.id + 1])
    end

    actions.each do |action|
      it "#{action} action should require permission to department" do
        get action, :id => @customer.id, :department_id => @department.id
        assert_response 403
      end
    end
  end


  describe 'with signed in user' do

    before(:each) do
      @department_1 = create(:department)
      @department_2 = create(:department)
      @customer_1 = create(:customer, :department_id => @department_1.id)
      @customer_2 = create(:customer, :department_id => @department_2.id)
      sign_in create(:user, :department_ids => [@department_1.id,@department_2.id])
    end

    describe 'GET #index' do

      it 'should show index with only list customers from accessed department' do
        get :index, :department_id => @department_1.id
        assert_response :success
        assert_template :index
        assert_equal [@customer_1], assigns(:customers)
      end

    end

    describe 'GET #new' do

      it 'should render the new template' do
        get :new, :department_id => @department_1.id
        assert_template :new
      end

      it 'should assign a new customer' do
        get :new, :department_id => @department_1.id
        assert_new_record_of Customer, assigns(:customer)
      end

    end

    describe 'POST #create' do

      it 'should create and redirect to customer' do
        post :create, :department_id => @department_1.id, :customer => attributes_for(:customer)
        refute_nil assigns(:department)
        refute_nil assigns(:customer)
        assert_redirected_to [@department_1, assigns(:customer)]
      end

      it 'should ignore parameters position, department_id and deactivated' do
        post :create, :department_id => @department_1.id, :customer => attributes_for(:customer, :department_id => 2, :position => 10)
        refute_nil assigns(:customer)
        refute_equal 10, assigns(:customer).position
        refute_equal 2, assigns(:customer).department_id
      end

      it 'should create arrangement for a new customer' do
        post :create, :department_id => @department_1.id, :customer => attributes_for(:customer, :department_id => 2)
        refute_nil assigns(:customer)
        refute_nil assigns(:customer).current_arrangement
      end

    end

    describe 'in methods with customer' do

      describe 'GET #show' do

        it 'should find requested customer' do
          get :show, :department_id => @customer_1.department_id, :id => @customer_1.id
          assert_equal @customer_1, assigns(:customer)
        end

        it 'should render show template' do
          get :show, :department_id => @customer_1.department_id, :id => @customer_1.id
          assert_template :show
        end

        it 'should get 404 if customer is from other department' do
          assert_raises ActiveRecord::RecordNotFound do
            get :show, department_id: @customer_1.department_id + 1, id: @customer_1.id
          end
        end
      end

      describe 'GET #edit' do

        it 'should find requested customer' do
          get :show, :department_id => @customer_1.department_id, :id => @customer_1.id
          assert_equal @customer_1, assigns(:customer)
        end

        it 'should render edit template' do
          get :edit, :department_id => @customer_1.department_id, :id => @customer_1.id
          assert_template :edit
        end

        it 'should get 404 if customer is from other department' do
          assert_raises ActiveRecord::RecordNotFound do
            get :edit, department_id: @customer_1.department_id + 1, id: @customer_1.id
          end
        end

      end

    end

    describe 'PUT #update' do

      it 'should update and redirect to customer' do
        post :update, {
            :id => @customer_1.id,
            :department_id => @customer_1.department_id,
            :customer => attributes_for(:customer)
        }
        refute_nil assigns(:department)
        refute_nil assigns(:customer)
        assert_redirected_to [assigns(:department), assigns(:customer)]
      end

      it 'should ignore parameters position and department_id' do
        put :update, {
            :id => @customer_1.id,
            :department_id => @customer_1.department_id,
            :customer => attributes_for(:customer, :department_id => 2, :position => 10)
        }
        refute_nil assigns(:customer)
        refute_equal 10, assigns(:customer).position
        refute_equal 2, assigns(:customer).department_id
      end

      it 'should keep deactivated customers below all activated'

      it 'should keep activated customers above all deactivated'

    end

    describe 'DELETE #destroy' do

      it 'should never be destroyed' do
        assert_raises ActionController::UrlGenerationError do
          delete :destroy, id: @customer_1.id, department_id: @customer_1.department_id
        end
      end

    end

    describe 'POST #sort' do

      before(:each) do
        @d3 = create(:department)
        @d4 = create(:department)
        @c1 = create(:customer, :department_id => @d3.id)
        @c2 = create(:customer, :department_id => @d3.id)
        @c3 = create(:customer, :department_id => @d3.id)
        sign_in create(:user, :department_ids => [@d3.id,@d4.id])
      end

      it 'should have initial order according to creation' do
        assert_equal 1, @c1.position
        assert_equal 2, @c2.position
        assert_equal 3, @c3.position
      end

      it 'should fail moving customers from other departments (no permission)' do
        post :sort, :position => 0, :item_id => @c2.id, :department_id => @department_1.id
        assert_response 403
      end

      it 'should fail for moving to other department' do
        post :sort, :position => 0, :item_id => @c2.id, :department_id => @d4.id
        assert_response :success, { :ok => false }.to_json
      end

      it 'should be able to move to top' do
        post :sort, :position => 0, :item_id => @c2.id, :department_id => @d3.id
        assert_response :success, { :ok => false }.to_json
      end

      it 'should not move customer further below than bottom'

      it 'should keep deactivated customers below all activated'

      it 'should keep activated customers above all deactivated'

    end

  end
end
