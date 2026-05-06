require "test_helper"

class MessagesControllerTest < ActionDispatch::IntegrationTest
  test "returns messages for a user" do
    get "/messages/#{users(:one).id}"

    assert_response :success
    assert response.parsed_body["messages"].any?
  end

  test "creates message with encrypted payload" do
    assert_difference "Message.count", 1 do
      post "/messages", params: {
        sender_id: users(:one).id,
        recipient_id: users(:two).id,
        ciphertext: "encrypted-ciphertext",
        encrypted_key: "wrapped-aes-key",
        nonce: "message-nonce",
        auth_tag: "message-auth-tag"
      }
    end

    assert_response :created
    message = Message.order(:created_at).last
    assert_equal "encrypted-ciphertext", message.ciphertext
    assert_equal "wrapped-aes-key", message.encrypted_key
    assert_equal "message-nonce", message.nonce
    assert_equal "message-auth-tag", message.auth_tag
  end
end
