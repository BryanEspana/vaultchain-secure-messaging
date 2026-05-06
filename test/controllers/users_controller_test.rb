require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  test "returns the public key for an existing user" do
    get "/users/#{users(:one).id}/key"

    assert_response :success
    assert_equal users(:one).public_key, response.parsed_body["public_key"]
  end
end
