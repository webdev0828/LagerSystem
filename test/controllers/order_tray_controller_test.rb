require 'test_helper'

describe OrderTrayController do

  describe 'with signed in user' do

    before(:each) do
      @department = create(:department)
      sign_in create(:user, :department_ids => [@department.id])
    end

    describe 'GET #index' do

      it 'should return http success' do
        get :index, :department_id => @department.id
        assert_response :success
      end

    end

  end

end
