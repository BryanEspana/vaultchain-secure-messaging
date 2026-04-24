require "test_helper"

class AuthControllerTest < ActionDispatch::IntegrationTest
  test "register creates a user with a bcrypt password digest" do
    assert_difference "User.count", 1 do
      post "/auth/register", params: {
        email: "robin@example.com",
        display_name: "Robin",
        password: "Ohara123!",
        password_confirmation: "Ohara123!"
      }
    end

    assert_response :created

    user = User.find_by!(email: "robin@example.com")
    assert_not_equal "Ohara123!", user.password_digest
    assert BCrypt::Password.new(user.password_digest).is_password?("Ohara123!")
    assert user.public_key.present?
    assert user.encrypted_private_key.present?
  end

  test "register does not expose password data in the response" do
    post "/auth/register", params: {
      email: "franky@example.com",
      display_name: "Franky",
      password: "Sunny123!",
      password_confirmation: "Sunny123!"
    }

    assert_response :created
    body = response.parsed_body

    assert_equal "Usuario registrado exitosamente", body["message"]
    assert body["user_id"].present?
    assert_not_includes body.keys, "password"
    assert_not_includes body.keys, "password_digest"
  end

  test "login verifies the bcrypt password digest" do
    post "/auth/login", params: {
      email: users(:one).email,
      password: "StrawHat123!"
    }

    assert_response :ok
    assert_equal users(:one).id, response.parsed_body["user_id"]
  end

  test "login rejects an invalid password" do
    post "/auth/login", params: {
      email: users(:one).email,
      password: "wrong-password"
    }

    assert_response :unauthorized
  end
end
