require "test_helper"
require "openssl"

class DigitalSignatureServiceTest < ActiveSupport::TestCase
  setup do
    @rsa_key = OpenSSL::PKey::RSA.generate(2048)
    @private_key_pem = @rsa_key.to_pem
    @public_key_pem = @rsa_key.public_key.to_pem
    @message = "Este es un mensaje secreto"
  end

  test "sign generates a valid base64 signature" do
    signature = DigitalSignatureService.sign(@message, @private_key_pem)
    assert signature.present?
    assert_nothing_raised do
      Base64.strict_decode64(signature)
    end
  end

  test "verify returns true for a valid signature" do
    signature = DigitalSignatureService.sign(@message, @private_key_pem)
    is_valid = DigitalSignatureService.verify(@message, signature, @public_key_pem)
    assert is_valid
  end

  test "verify returns false for an invalid signature" do
    signature = DigitalSignatureService.sign(@message, @private_key_pem)
    invalid_message = "Este es un mensaje alterado"
    is_valid = DigitalSignatureService.verify(invalid_message, signature, @public_key_pem)
    assert_not is_valid
  end
end
