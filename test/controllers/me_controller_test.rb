require 'test_helper'

describe MeController do

  it_should_require_user_for [:edit, :update]

  describe 'with logged in user' do

    it 'should succeed for logged in user' do
      sign_in user = create(:user)
      get :edit
      assert_equal user, assigns(:user)
    end

    it 'should fail update without current password' do
      sign_in create(:user, :full_name => 'Old Name')

      put :update, { :user => {
          :full_name => 'New Name'
      }}

      assert_template :edit
      refute_empty assigns(:user).errors
    end

    it 'should succeed update with current password' do
      department = create(:department)
      sign_in create(:user, {
          :password => 'correct password',
          :department_ids => [department.id],
          :full_name => 'Old Name'
      })

      put :update, :user => {
          :current_password => 'correct password',
          :full_name => 'New Name'
      }

      assert_redirected_to [department, :customers]
      assert_empty assigns(:user).errors
      assert_equal 'New Name', assigns(:user).full_name
    end

    it 'should fail to update admin attributes' do
      department1 = create(:department)
      department2 = create(:department)

      sign_in create(:user, {
          :password => 'correct password',
          :department_ids => [department1.id,department2.id],
          :full_name => 'Old Name',
          :role => 'default'
      })

      put :update, :user => {
          :current_password => 'correct password',
          :department_ids => [department1.id],
          :full_name => 'New Name',
          :role => 'admin'
      }

      assert_redirected_to root_path
      assert_empty assigns(:user).errors
      assert_equal 'New Name', assigns(:user).full_name
      assert_equal [department1.id,department2.id], assigns(:user).department_ids
      assert_equal 'default', assigns(:user).role
    end
    # it "should succeed password update if password and confirmation matches"
  end


end
