require 'test_helper'

class GenesControllerTest < ActionController::TestCase
  setup do
    @gene = genes(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:genes)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create gene" do
    assert_difference('Gene.count') do
      post :create, :gene => @gene.attributes
    end

    assert_redirected_to gene_path(assigns(:gene))
  end

  test "should show gene" do
    get :show, :id => @gene.to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => @gene.to_param
    assert_response :success
  end

  test "should update gene" do
    put :update, :id => @gene.to_param, :gene => @gene.attributes
    assert_redirected_to gene_path(assigns(:gene))
  end

  test "should destroy gene" do
    assert_difference('Gene.count', -1) do
      delete :destroy, :id => @gene.to_param
    end

    assert_redirected_to genes_path
  end
end
