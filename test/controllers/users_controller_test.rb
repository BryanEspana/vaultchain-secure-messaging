require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  test "returns the public key for an existing user" do
    get "/users/#{users(:one).id}/key"

    assert_response :ok
    assert_equal users(:one).public_key, response.parsed_body["public_key"]
  end

  test "returns not found when user does not exist" do
    get "/users/00000000-0000-0000-0000-000000000000/key"

    assert_response :not_found
    assert_equal "Usuario no encontrado", response.parsed_body["error"]
  end

  test "returns not found when user has no public key" do
    user = User.create!(
      email: "chopper@example.com",
      display_name: "Chopper",
      password: "CottonCandy123!",
      password_confirmation: "CottonCandy123!"
    )

    get "/users/#{user.id}/key"

    assert_response :not_found
    assert_equal "Llave pública no encontrada para este usuario", response.parsed_body["error"]
  end
end
