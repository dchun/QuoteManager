require 'test_helper'

class TemplatesControllerTest < ActionController::TestCase
  setup do
    @template = templates(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:templates)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create template" do
    assert_difference('Template.count') do
      post :create, template: { account_id: @template.account_id, content: @template.content, description: @template.description, name: @template.name }
    end

    assert_redirected_to template_path(assigns(:template))
  end

  test "should show template" do
    get :show, id: @template
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @template
    assert_response :success
  end

  test "should update template" do
    patch :update, id: @template, template: { account_id: @template.account_id, content: @template.content, description: @template.description, name: @template.name }
    assert_redirected_to template_path(assigns(:template))
  end

  test "should destroy template" do
    assert_difference('Template.count', -1) do
      delete :destroy, id: @template
    end

    assert_redirected_to templates_path
  end
end
