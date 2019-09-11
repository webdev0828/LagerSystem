require 'test_helper'

describe StoragesController do

  describe 'with logged in user' do

    before(:each) do
      @d1 = create(:department)
      @d_ = create(:department)
      @s1 = create(:bulk_storage, :department_id => @d1.id)
      @s_ = create(:bulk_storage, :department_id => @d_.id)
      @s2 = create(:organized_storage, :department_id => @d1.id)
      @s3 = create(:bulk_storage, :department_id => @d1.id)
      sign_in create(:user, :department_ids => [@d1.id])
    end

    describe 'GET #index' do

      it 'should assign @storages with a list of storages belonging to chosen department' do
        get :index, :department_id => @d1.id
        assert_equal [@s1, @s2, @s3], assigns(:storages)

      end

      it 'should render index template' do
        get :index, :department_id => @d1.id
        assert_response :success
        assert_template :index
      end

    end

    describe 'POST #sort' do

      it 'should have initial order according to creation' do

        department = create(:department)

        s1 = create(:bulk_storage, :department_id => department.id)
        s2 = create(:bulk_storage, :department_id => department.id)
        s3 = create(:bulk_storage, :department_id => department.id)

        assert_equal 1, s1.position
        assert_equal 2, s2.position
        assert_equal 3, s3.position
      end

      it 'should fail moving storages from other departments (no permission)' do
        post :sort, :position => 0, :item_id => @s2.id, :department_id => @d_.id
        assert_response 403
      end

      it 'should fail for moving to other department' do
        post :sort, :position => 0, :item_id => @s_.id, :department_id => @d1.id
        assert_response :success, { :ok => false }.to_json
      end

      it 'should be able to move to top' do
        post :sort, :position => 0, :item_id => @s2.id, :department_id => @d1.id
        assert_response :success, { :ok => true }.to_json
      end

      it 'should not move storage further below than bottom'

    end

    describe 'GET #shelfs' do

      it 'should return json {"shelfs":0} for bulk storages' do
        get :shelfs, :storage_id => @s1.id, :department_id => @d1.id
        assert_response :success, '{"shelfs":0}'
      end

      it 'should return correct count for organized storage' do
        @s4 = create(:organized_storage, :shelf_count => 3, :department_id => @d1.id)
        get :shelfs, :storage_id => @s4.id, :department_id => @d1.id
        assert_response :success, '{"shelfs":3}'
      end

    end

  end

end