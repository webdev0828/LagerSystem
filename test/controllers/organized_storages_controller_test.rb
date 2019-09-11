require 'test_helper'

describe OrganizedStoragesController do

  actions = [ :show, :edit, :update, :print_shelf ]
  it_should_require_user_for actions, :id => 1, :department_id => 1

  describe 'forbid user with no permission to department' do

    before(:each) do
      @department = create(:department)
      @organized_storage = create(:organized_storage, :department_id => @department.id)
      sign_in create(:user, :role => 'default', :department_ids => [@department.id + 1])
    end

    actions.each do |action|
      it "#{action} action should require permission to department" do
        get action, :id => @organized_storage.id, :department_id => @department.id
        assert_response 403
      end
    end
  end

  describe 'with signed in user' do

    before(:each) do
      @department = create(:department)
      @organized_storage = create(:organized_storage, :department_id => @department.id)
      sign_in create(:user, :role => 'default', :department_ids => [@department.id])
    end

    describe 'GET #show' do

      it 'should return http success' do
        get :show, id: @organized_storage.id, department_id: @department.id
        assert_response :success
      end

      it 'should render show template with given organized storage' do
        get :show, id: @organized_storage.id, department_id: @department.id
        assert_template :show
      end

      it 'should show info of the free space in a storage'

    end

    describe 'GET #edit' do

      it 'should return http success' do
        get :edit, id: @organized_storage.id, department_id: @department.id
        assert_response :success
      end

      it 'should render edit template with given organized storage' do
        get :edit, id: @organized_storage.id, department_id: @department.id
        assert_template :edit
      end

    end

    describe 'PUT #update' do

      it 'should redirect to organized storage with flash on successful update'

      it 'should render edit template with error when name is missing'

    end

    describe 'GET #print_shelf' do

      it 'should return http success' do
        get :print_shelf, format: :pdf, id: @organized_storage.id, department_id: @department.id
        assert_response :success
      end

      it 'should not respond to html, xml or json format'

      it 'should render a pdf with shelf data depending on a parameter named shelf'

      it 'should default to rendering shelf 1'

      it 'should redirect to organized storage with error when shelf number is invalid'

      it 'should redirect to organized storage with error when shelf number is or out of bound'

    end

  end

end
