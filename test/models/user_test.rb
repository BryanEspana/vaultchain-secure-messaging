require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "hashes password with bcrypt instead of storing plaintext" do
    user = User.create!(
      email: "nami@example.com",
      display_name: "Nami",
      password: "Navigation123!",
      password_confirmation: "Navigation123!"
    )

    assert_not_equal "Navigation123!", user.password_digest
    assert BCrypt::Password.new(user.password_digest).is_password?("Navigation123!")
  end

  test "authenticates with the original password only" do
    user = users(:one)

    assert user.authenticate("StrawHat123!")
    assert_not user.authenticate("wrong-password")
  end

  test "requires a password when creating users" do
    user = User.new(email: "brook@example.com", display_name: "Brook")

    assert_not user.valid?
    assert_includes user.errors[:password], "can't be blank"
  end
end
