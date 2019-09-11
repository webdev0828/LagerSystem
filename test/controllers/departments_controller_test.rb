require 'test_helper'

describe DepartmentsController do

  it_should_require_user_for [:index]

  describe 'GET #index' do

    before(:each) do
      @department_1 = create(:department)
      @department_2 = create(:department)
    end

    describe 'logged in user with access to one department' do
      it 'should redirect to customer index of that department' do
        sign_in create(:user, :department_ids => [@department_1.id])
        get :index
        assert_redirected_to [@department_1,:customers]
      end
    end

    describe 'logged in user access to multible departments' do
      it 'should show list of departments' do
        sign_in create(:user, :department_ids => [@department_1.id,@department_2.id])
        get :index
        assert_response :success
        assert_template :index
        assert_equal [@department_1,@department_2], assigns(:departments)
      end
    end

  end
end
