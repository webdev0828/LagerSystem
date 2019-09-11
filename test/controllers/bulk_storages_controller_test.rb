require 'test_helper'

describe BulkStoragesController do

  actions = [ :show, :new, :edit, :create, :update, :destroy ]
  it_should_require_user_for actions, :id => 1, :department_id => 1

  describe 'forbid user with no permission to department' do

    before(:each) do
      @department = create(:department)
      @bulk_storage = create(:bulk_storage, :department_id => @department.id)
      sign_in create(:user, :role => 'default', :department_ids => [@department.id + 1])
    end

    actions.each do |action|
      it "#{action} action should require permission to department" do
        get action, :id => @bulk_storage.id, :department_id => @department.id
        assert_response 403
      end
    end
  end

  describe 'with signed in user' do

    before(:each) do
      @department = create(:department)
      @bulk_storage = create(:bulk_storage, :department_id => @department.id)
      @transfer = create(:bulk_storage, :department_id => @department.id)
      @lobby = create(:bulk_storage, :department_id => @department.id)
      @department.update_attributes(transfer: @transfer, lobby: @lobby)
      sign_in create(:user, :department_ids => [@department.id])
    end

    describe 'GET #new' do

      it 'should return http success' do
        get :new, department_id: @department.id
        assert_response :success
      end

      it 'should render new template with new bulk_storage' do
        get :new, department_id: @department.id
        assert_template :new
      end

    end

    describe 'GET #show' do

      it 'should return http success' do
        get :show, id: @bulk_storage.id, department_id: @department.id
        assert_response :success
      end

      it 'should render show template with given bulk storage' do
        get :show, id: @bulk_storage.id, department_id: @department.id
        assert_template :show
      end

    end

    describe 'GET #edit' do

      it 'should return http success' do
        get :edit, id: @bulk_storage.id, department_id: @department.id
        assert_response :success
      end

      it 'should render edit template with given bulk storage' do
        get :edit, id: @bulk_storage.id, department_id: @department.id
        assert_template :edit
      end

    end

    describe 'POST #create' do

      it 'should redirect to bulk storage with flash on successful create' do
        post :create, department_id: @department.id, bulk_storage: attributes_for(:bulk_storage)
        assert_redirected_to [@department, assigns(:bulk_storage)]
      end

      it 'should render new template with error when name is missing' do
        post :create, department_id: @department.id, bulk_storage: { name: '' }
        assert_response :success
        assert_template :new
        assert_includes assigns(:bulk_storage).errors[:name], 'skal udfyldes'
      end

    end

    describe 'PUT #update' do

      it 'should redirect to bulk storage with flash on successful update' do
        put :update, :id => @bulk_storage.id, :department_id => @department.id, :bulk_storage => { :name => 'Lolcat' }
        assert_redirected_to [@department, @bulk_storage]
        assert_flash_notice 'Lagret er nu opdateret.'
      end

      it 'should render edit template with error when name is missing' do
        put :update, id: @bulk_storage.id, department_id: @department.id, bulk_storage: {name: ''}
        assert_response :success
        assert_template :edit
        assert_equal @bulk_storage, assigns(:bulk_storage)
        assert_includes assigns(:bulk_storage).errors[:name], 'skal udfyldes'
      end

    end

    describe 'DELETE #destroy' do

      it 'should redirect to storages with notice on successful destroy' do
        delete :destroy, id: @bulk_storage.id, department_id: @department.id
        assert_redirected_to [@department, :storages]
        assert_flash_notice 'Lageret er nu slettet.'
      end

      it 'should redirect to bulk storage with error when storage is a transfer storage' do
        delete :destroy, id: @department.transfer.id, department_id: @department.id
        assert_redirected_to [@department,@department.transfer]
        assert_flash_alert 'Du kan ikke slette afdelingens transferlager.'
      end

      it 'should redirect to bulk storage with error when storage is a lobby storage' do
        delete :destroy, id: @department.lobby.id, department_id: @department.id
        assert_redirected_to [@department,@department.lobby]
        assert_flash_alert 'Du kan ikke slette afdelingens lobbylager.'
      end

      it 'should redirect to bulk storage with error when storage is not empty of pallets' do
        customer = create :customer, department_id: @department.id
        arrival = create :arrival, customer_id: customer.id, count: 100, capacity: 15
        @bulk_storage.pallets << arrival.pallets
        @bulk_storage.save
        delete :destroy, id: @bulk_storage.id, department_id: @department.id
        assert_redirected_to [@department,@bulk_storage]
        assert_flash_alert 'Du kan kun slette tomme lagre.'
      end

    end

  end

end
