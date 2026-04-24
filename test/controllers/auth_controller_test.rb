require "test_helper"

class AuthControllerTest < ActionDispatch::IntegrationTest
  test "login verifies bcrypt password hash and emits a decodable JWT" do
    user = users(:one)

    post "/auth/login", params: {
      email: user.email,
      password: "StrawHat123!"
    }

    assert_response :success

    body = response.parsed_body
    assert_equal "Login exitoso", body["message"]
    assert_equal user.id, body["user_id"]
    assert body["token"].present?
    assert_not_equal "JWT_PENDIENTE", body["token"]

    decoded_token = JsonWebToken.decode(body["token"])
    assert_equal user.id, decoded_token[:user_id]
    assert decoded_token[:exp].present?
  end

  test "login rejects invalid password without emitting JWT" do
    post "/auth/login", params: {
      email: users(:one).email,
      password: "wrong-password"
    }

    assert_response :unauthorized

    body = response.parsed_body
    assert_equal "Credenciales inválidas", body["error"]
    assert_nil body["token"]
  end
end
