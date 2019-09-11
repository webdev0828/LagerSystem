require 'test_helper'

describe UsersController do

  actions = [ :index, :show, :new, :create, :edit, :update, :destroy, :lock, :unlock ]
  it_should_require_user_for actions, :id => 1

  describe 'forbid default user' do

    before(:each) do
      @user1 = create(:user)
      @user2 = create(:user, :role => 'admin')
      sign_in @user1
    end

    actions.each do |action|
      it "#{action} action should require admin" do
        params = { :id => @user2.id }
        params[:user] = { :username => 'lolcat'} unless action == :new
        get action, params
        assert_response 403
      end
    end

  end

  describe 'with admin user signed in' do

    before(:each) do
      sign_in create(:user, :role => 'admin')
    end

    describe 'GET #index' do

      it 'should render the index template' do
        get :index
        assert_template :index
      end

      it 'should assign @users' do
        user = create(:user)
        get :index
        assert_includes assigns(:users), user
      end

    end

    describe 'POST #create' do

      it 'should redirect to that user with a notice on successful save' do
        post :create, :user => attributes_for(:user)
        refute_nil assigns(:user)
        assert_redirected_to assigns(:user)
      end

      it 'should render form if user is not valid' do
        post :create, :user => attributes_for(:user, :email => "")
        refute_nil assigns(:user)
        refute assigns(:user).valid?
        assert assigns(:user).new_record?
        assert_template :new
      end

      it 'should send an email to that user'

    end

    describe 'GET #show' do

      it 'should find the right user' do
        user = create(:user)
        get :show, :id => user.id
        assert_response :success
        assert_equal user, assigns(:user)
      end

      it 'should render the show template' do
        user = create(:user)
        get :show, :id => user.id
        assert_template :show
      end

    end

    describe 'GET #new' do

      it 'should render the new template with a new User' do
        get :new
        assert_response :success
        assert_template :new
        assert_kind_of User, assigns(:user)
      end

    end

    describe 'GET #edit' do

      it 'should render the edit template for existing user' do
        user = create(:user)
        get :edit, :id => user.id
        assert_response :success
        assert_template :edit
        assert_equal user, assigns(:user)
      end

    end

    describe 'PUT #update' do

      it 'should update and redirect to user' do
        user = create(:user, :department_ids => [1], :role => 'default')
        put :update, {
            :id => user.id,
            :user => attributes_for(:user, :department_ids => [1,2,3], :role => 'admin')
        }
        assert_redirected_to user
        assert_equal user, assigns(:user)
        assert_equal 'admin', assigns(:user).role
        assert_equal [1,2,3], assigns(:user).department_ids
      end

      it 'should fail when downgrading role for logged in admin user' do
        admin = create(:user, :role => 'admin')
        sign_in admin
        put :update, {
            :id => admin.id,
            :user => attributes_for(:user, :role => 'default')
        }
        assert_response :success
        assert_template :edit
        assert_equal admin, assigns(:user)
        assert_equal 'admin', assigns(:user).role
        assert_equal ['Du kan ikke sætte din egen bruger til "standard"'], assigns(:user).errors[:role]
      end

    end

    describe 'DELETE #destroy' do

      it 'should destroy user and redirect to users_path' do
        user = create(:user)
        assert_difference 'User.count', -1, 'The user should not be destroyed' do
          delete :destroy, id: user.id
        end
        assert_redirected_to users_path
      end

      it 'should not be possible to destroy the logged in admin' do
        admin = create(:user, :role => 'admin')
        sign_in admin
        assert_no_difference 'User.count', 'The user should not be destroyed' do
          delete :destroy, id: admin.id
        end
        assert_redirected_to [admin]
        assert_equal 'Du kan ikke slette din egen bruger', flash[:alert]
      end

    end

    describe 'PUT #lock' do

      it 'should deactivate and redirect to a user' do
        user = create(:user)
        refute user.access_locked?
        put :lock, :id => user.id
        assert_redirected_to user
        assert assigns(:user).access_locked?
        assert_equal 'Brugeren er nu deaktiveret.', flash[:notice]
      end

      it 'should not deactivate the logged in admin' do
        user = create(:user, :role => 'admin')
        refute user.access_locked?
        sign_in user
        put :lock, :id => user.id
        assert_redirected_to user
        refute assigns(:user).access_locked?
        assert_equal 'Du kan ikke deaktivere din egen bruger', flash[:alert]
      end
    end

    describe 'PUT #unlock' do

      it 'should activate and redirect to a user' do
        user = create(:user)
        user.lock_access!
        assert user.access_locked?
        put :unlock, :id => user.id
        assert_redirected_to user
        refute assigns(:user).access_locked?
        assert_equal 'Brugeren er nu aktiveret.', flash[:notice]
      end

    end

  end
end
