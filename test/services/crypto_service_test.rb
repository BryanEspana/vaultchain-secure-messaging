require "test_helper"

class CryptoServiceTest < ActiveSupport::TestCase
  # ============================================
  # Key Generation Tests
  # ============================================

  test "generate_keys returns a hash with public_key and encrypted_private_key" do
    result = CryptoService.generate_keys("test_password")

    assert_instance_of Hash, result
    assert result.key?(:public_key), "Result should have :public_key key"
    assert result.key?(:encrypted_private_key), "Result should have :encrypted_private_key key"
  end

  test "generate_keys creates valid RSA-2048 key pair" do
    result = CryptoService.generate_keys("test_password")
    public_key_pem = result[:public_key]

    # Verify the public key can be loaded
    public_key = OpenSSL::PKey::RSA.new(public_key_pem)
    assert_equal 2048, public_key.n.num_bits, "Public key should be RSA-2048"
  end

  test "generate_keys creates different keys on each call" do
    result1 = CryptoService.generate_keys("same_password")
    result2 = CryptoService.generate_keys("same_password")

    # Keys should be different due to random salt/IV
    assert_not_equal result1[:public_key], result2[:public_key], "Each call should generate unique key pair"
    assert_not_equal result1[:encrypted_private_key], result2[:encrypted_private_key], "Encrypted private keys should be different"
  end

  test "generate_keys public key is in PEM format" do
    result = CryptoService.generate_keys("test_password")

    assert result[:public_key].include?("-----BEGIN PUBLIC KEY-----"), "Public key should be in PEM format"
    assert result[:public_key].include?("-----END PUBLIC KEY-----"), "Public key should be in PEM format"
  end

  test "generate_keys encrypted private key is Base64 encoded" do
    result = CryptoService.generate_keys("test_password")

    # Should be valid Base64
    assert_nothing_raised do
      Base64.strict_decode64(result[:encrypted_private_key])
    end
  end

  # ============================================
  # Key Cipher (Encryption) Tests
  # ============================================

  test "encrypt_private_key produces Base64 encoded output" do
    result = CryptoService.generate_keys("test_password")

    # Should decode without error
    decoded = Base64.strict_decode64(result[:encrypted_private_key])
    assert decoded.present?, "Encrypted data should not be empty"

    # Minimum size: salt(16) + iv(12) + auth_tag(16) + some encrypted data
    assert decoded.length >= 44, "Encrypted data should be at least 44 bytes"
  end

  test "encrypt_private_key uses unique salt each time" do
    result1 = CryptoService.generate_keys("same_password")
    result2 = CryptoService.generate_keys("same_password")

    decoded1 = Base64.strict_decode64(result1[:encrypted_private_key])
    decoded2 = Base64.strict_decode64(result2[:encrypted_private_key])

    # First 16 bytes are salt - should be different
    salt1 = decoded1[0...16]
    salt2 = decoded2[0...16]

    assert_not_equal salt1, salt2, "Salt should be unique for each encryption"
  end

  test "encrypt_private_key uses unique IV each time" do
    result1 = CryptoService.generate_keys("same_password")
    result2 = CryptoService.generate_keys("same_password")

    decoded1 = Base64.strict_decode64(result1[:encrypted_private_key])
    decoded2 = Base64.strict_decode64(result2[:encrypted_private_key])

    # Bytes 16-28 are IV (12 bytes) - should be different
    iv1 = decoded1[16...28]
    iv2 = decoded2[16...28]

    assert_not_equal iv1, iv2, "IV should be unique for each encryption"
  end

  test "encrypt_private_key produces different output for different passwords" do
    result1 = CryptoService.generate_keys("password1")
    result2 = CryptoService.generate_keys("password2")

    assert_not_equal result1[:encrypted_private_key], result2[:encrypted_private_key],
      "Different passwords should produce different encrypted private keys"
  end

  # ============================================
  # Decryption Tests (Key Cipher)
  # ============================================

  test "decrypt_private_key successfully decrypts with correct password" do
    password = "correct_password"
    result = CryptoService.generate_keys(password)

    decrypted_pem = CryptoService.decrypt_private_key(
      result[:encrypted_private_key],
      password
    )

    assert decrypted_pem.include?("-----BEGIN RSA PRIVATE KEY-----"),
      "Decrypted private key should be in PEM format"
    assert decrypted_pem.include?("-----END RSA PRIVATE KEY-----"),
      "Decrypted private key should be in PEM format"
  end

  test "decrypt_private_key fails with incorrect password" do
    result = CryptoService.generate_keys("correct_password")

    assert_raises(OpenSSL::Cipher::CipherError) do
      CryptoService.decrypt_private_key(result[:encrypted_private_key], "wrong_password")
    end
  end

  test "decrypt_private_key roundtrip preserves RSA key" do
    password = "test_password_123"
    result = CryptoService.generate_keys(password)

    # Decrypt the private key
    decrypted_pem = CryptoService.decrypt_private_key(
      result[:encrypted_private_key],
      password
    )

    # Load the decrypted private key
    private_key = OpenSSL::PKey::RSA.new(decrypted_pem)

    # Verify it matches the original public key
    assert private_key.public_key.to_pem == result[:public_key],
      "Decrypted private key should match the original public key"
  end

  test "decrypt_private_key can encrypt and decrypt data with the key pair" do
    password = "secure_password"
    result = CryptoService.generate_keys(password)

    # Decrypt private key
    decrypted_pem = CryptoService.decrypt_private_key(
      result[:encrypted_private_key],
      password
    )
    private_key = OpenSSL::PKey::RSA.new(decrypted_pem)
    public_key = OpenSSL::PKey::RSA.new(result[:public_key])

    # Test encryption/decryption
    original_data = "Secret message for testing"
    encrypted = public_key.public_encrypt(original_data)
    decrypted = private_key.private_decrypt(encrypted)

    assert_equal original_data, decrypted,
      "Should be able to encrypt with public key and decrypt with private key"
  end

  test "encrypt_message returns encrypted payload without plaintext" do
    keys = CryptoService.generate_keys("recipient_password")
    plaintext = "Mensaje secreto para el destinatario"
    encrypted_message = CryptoService.encrypt_message(plaintext, keys[:public_key])

    assert_equal %i[auth_tag ciphertext encrypted_key nonce], encrypted_message.keys.sort
    assert_not_equal plaintext, encrypted_message[:ciphertext]
    assert_not Base64.strict_decode64(encrypted_message[:ciphertext]).include?(plaintext)
    assert_equal 12, Base64.strict_decode64(encrypted_message[:nonce]).bytesize
    assert_equal 16, Base64.strict_decode64(encrypted_message[:auth_tag]).bytesize
    assert Base64.strict_decode64(encrypted_message[:encrypted_key]).bytesize.positive?
  end

  test "decrypt_message_with_password recovers AES key and plaintext for recipient" do
    password = "secure_password"
    keys = CryptoService.generate_keys(password)
    plaintext = "Mensaje secreto para el destinatario"
    encrypted_message = CryptoService.encrypt_message(plaintext, keys[:public_key])

    decrypted_message = CryptoService.decrypt_message_with_password(
      encrypted_message,
      keys[:encrypted_private_key],
      password
    )

    assert_equal plaintext, decrypted_message
  end

  # ============================================
  # Security & Edge Case Tests
  # ============================================

  test "generate_keys handles empty password" do
    result = CryptoService.generate_keys("")

    assert result.key?(:public_key)
    assert result.key?(:encrypted_private_key)

    # Should still be able to decrypt with empty password
    decrypted_pem = CryptoService.decrypt_private_key(
      result[:encrypted_private_key],
      ""
    )
    assert decrypted_pem.include?("-----BEGIN RSA PRIVATE KEY-----")
  end

  test "generate_keys handles special characters in password" do
    password = "p@ssw0rd!#$%^&*()_+-=[]{}|;':\",./<>?"
    result = CryptoService.generate_keys(password)

    decrypted_pem = CryptoService.decrypt_private_key(
      result[:encrypted_private_key],
      password
    )

    assert decrypted_pem.include?("-----BEGIN RSA PRIVATE KEY-----"),
      "Should handle special characters in password"
  end

  test "generate_keys handles unicode password" do
    password = "密码123"
    result = CryptoService.generate_keys(password)

    decrypted_pem = CryptoService.decrypt_private_key(
      result[:encrypted_private_key],
      password
    )

    assert decrypted_pem.include?("-----BEGIN RSA PRIVATE KEY-----"),
      "Should handle unicode characters in password"
  end

  test "generate_keys produces sufficiently long encrypted output" do
    result = CryptoService.generate_keys("test_password")
    decoded = Base64.strict_decode64(result[:encrypted_private_key])

    # RSA-2048 private key PEM is ~1700 bytes, encrypted should be larger than raw
    assert decoded.length > 1000, "Encrypted data should be substantial"
  end

  test "decrypt_private_key raises error on tampered data" do
    result = CryptoService.generate_keys("test_password")
    encrypted_data = result[:encrypted_private_key]

    # Tamper with the encrypted data
    decoded = Base64.strict_decode64(encrypted_data)
    decoded[50] = (decoded[50].ord ^ 0xFF).chr
    tampered = Base64.strict_encode64(decoded)

    assert_raises(OpenSSL::Cipher::CipherError) do
      CryptoService.decrypt_private_key(tampered, "test_password")
    end
  end

  test "decrypt_private_key raises error on truncated data" do
    result = CryptoService.generate_keys("test_password")
    encrypted_data = result[:encrypted_private_key]

    # Truncate the data
    truncated = encrypted_data[0...encrypted_data.length / 2]

    assert_raises(ArgumentError) do
      CryptoService.decrypt_private_key(truncated, "test_password")
    end
  end
end
