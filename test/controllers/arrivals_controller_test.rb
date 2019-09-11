require 'test_helper'

describe ArrivalsController do

  actions = [:index, :show, :new, :edit, :create, :update, :destroy, :autofill]
  it_should_require_user_for actions, id: 1, customer_id: 1, department_id: 1

  describe 'forbid user with no permission to department' do
    actions.each do |action|
      it "#{action} action should require permission to department" do
        department = create(:department)
        other_department = create(:department)
        customer = create(:customer, department_id: department.id)
        arrival = create(:arrival, customer_id: customer.id)
        sign_in create(:user, role: 'default', department_ids: [other_department.id])
        get action, id: arrival.id, customer_id: customer.id, department_id: department.id
        assert_response 403
      end
    end
  end

  describe 'with signed in user' do

    before(:each) do
      @department = create(:department)
      @customer = create(:customer, department_id: @department.id)
      sign_in create(:user, department_ids: [@department.id])
    end

    describe 'GET #show' do

      it 'should return http success' do
        arrival = create(:arrival, customer_id: @customer.id)
        get :show, id: arrival.id, customer_id: @customer.id, department_id: @department.id
        assert_response :success
        assert_template :show
      end

    end

    describe 'POST #create' do

      it 'should require a lot of stuff' do
        post :create, arrival: {lol: 'cat'}, customer_id: @customer.id, department_id: @department.id
        assert_response :success
        assert_template :new
        refute_empty assigns(:arrival).errors
      end

      # it 'should not be possible to add goods where best_before is in the past' do
      #   post :create, arrival: attributes_for(:arrival, best_before: date_time_params(10.days.ago)), customer_id: @customer.id, department_id: @department.id
      #   assert_response :success
      #   assert_template :new
      #   assert_includes assigns(:arrival).errors[:best_before], 'in the past'
      # end

      describe 'with count greater than capacity' do
        it 'should create multiple pallets not exceeding capacity' do
          post :create, arrival: attributes_for(:arrival, count: 18, capacity: 5), customer_id: @customer.id, department_id: @department.id
          assert_redirected_to [@department, @customer, assigns(:arrival)]
          assert_equal 4, assigns(:arrival).pallets.size
          assert_equal [5,5,5,3], assigns(:arrival).pallets.map(&:count)
        end
      end

    end

    describe 'PUT #update' do

      it 'should allow update on name, number, batch, trace' do
        arrival = create :arrival, customer_id:  @customer.id, name: 'Fisk', number: '123', batch: '123', trace: '123', count: 10, capacity: 95
        params = { name: 'Hat', number: '789', batch: '789', trace: '789' }
        put :update, arrival: params, id: arrival.id, customer_id: @customer.id, department_id: @department.id
        assert_redirected_to [@department, @customer, assigns(:arrival)]
        assert_equal params[:name], assigns(:arrival).name
        assert_equal params[:number], assigns(:arrival).number
        assert_equal params[:batch], assigns(:arrival).batch
        assert_equal params[:trace], assigns(:arrival).trace
      end

      it 'should update all pallets'
      # do
      #   pending 'Make tests to see if pallets change as well'
      # end

      it 'should not allow (filter out) update on payment critical attributes' do
        arrival = create :arrival, customer_id:  @customer.id, count: 70, capacity: 70, pallet_type_id: 2, weight: 0.5
        params = attributes_for :arrival, count: 72, capacity: 72, pallet_type_id: 1, weight: 0.4

        put :update, arrival: params, id: arrival.id, customer_id: @customer.id, department_id: @department.id
        assert_redirected_to [@department, @customer, assigns(:arrival)]
        assert_equal arrival.count, assigns(:arrival).count
        assert_equal arrival.capacity, assigns(:arrival).capacity
        assert_equal arrival.pallet_type_id, assigns(:arrival).pallet_type_id
        assert_equal arrival.weight, assigns(:arrival).weight
      end

    end

  end

end
