require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  test "should get key" do
    get users_key_url
    assert_response :success
  end
end
