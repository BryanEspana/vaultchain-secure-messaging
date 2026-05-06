require "openssl"
require "base64"


class CryptoService
  # Generate RSA key pair and encrypt the private key using AES
  def self.generate_keys(password)
    rsa_key = OpenSSL::PKey::RSA.new(2048)

    public_key = rsa_key.public_key.to_pem
    encrypted_private_key = encrypt_private_key(rsa_key.to_pem, password)

    {
      public_key: public_key,
      encrypted_private_key: encrypted_private_key
    }
  end

  private

  # Encrypt private key using AES-256-GCM with PBKDF2-derived key
  def self.encrypt_private_key(private_key_pem, password)
    cipher = OpenSSL::Cipher.new("aes-256-gcm")
    cipher.encrypt

    # Derive key from password using PBKDF2 with 100,000 iterations
    salt = OpenSSL::Random.random_bytes(16)
    key = OpenSSL::PKCS5.pbkdf2_hmac(password, salt, 100_000, 32, "SHA256")

    cipher.key = key
    # GCM 12-bytes
    iv = OpenSSL::Random.random_bytes(12)
    cipher.iv = iv

    encrypted = cipher.update(private_key_pem) + cipher.final
    auth_tag = cipher.auth_tag

    # Combine salt, IV, auth_tag, and encrypted data, then Base64 encode
    # Format: [Salt (16)] [IV (12)] [Auth_Tag (16)] [Encrypted Data]
    combined = salt + iv + auth_tag + encrypted
    Base64.strict_encode64(combined)
  end

  # Decrypt private key (for future use when retrieving keys)
  def self.decrypt_private_key(encrypted_data, password)
    combined = Base64.strict_decode64(encrypted_data)

    # Extract salt (first 16 bytes), IV (next 12 bytes), auth_tag (next 16 bytes), and encrypted data
    salt = combined[0...16]
    iv = combined[16...28] # IV is 12 bytes for GCM
    auth_tag = combined[28...44]
    encrypted = combined[44..-1]

    # Derive same key from password using PBKDF2
    key = OpenSSL::PKCS5.pbkdf2_hmac(password, salt, 100_000, 32, "SHA256")

    cipher = OpenSSL::Cipher.new("aes-256-gcm")
    cipher.decrypt
    cipher.key = key
    cipher.iv = iv
    cipher.auth_tag = auth_tag

    cipher.update(encrypted) + cipher.final
  end

  # Hybrid encryption: AES-256-GCM for message, RSA-OAEP for AES key
  def self.encrypt_message(plaintext, recipient_public_key_pem)
    # Generate ephemeral AES-256 key
    aes_key = OpenSSL::Random.random_bytes(32)

    # Encrypt message with AES-256-GCM
    cipher = OpenSSL::Cipher.new("aes-256-gcm")
    cipher.encrypt
    cipher.key = aes_key
    nonce = OpenSSL::Random.random_bytes(12) # GCM nonce is 12 bytes
    cipher.iv = nonce

    ciphertext = cipher.update(plaintext) + cipher.final
    auth_tag = cipher.auth_tag

    # Encrypt AES key with recipient's public key using RSA-OAEP
    rsa_public_key = OpenSSL::PKey::RSA.new(recipient_public_key_pem)
    encrypted_key = rsa_public_key.public_encrypt(aes_key, OpenSSL::PKey::RSA::PKCS1_OAEP_PADDING)

    {
      ciphertext: Base64.strict_encode64(ciphertext),
      encrypted_key: Base64.strict_encode64(encrypted_key),
      nonce: Base64.strict_encode64(nonce),
      auth_tag: Base64.strict_encode64(auth_tag)
    }
  end

  # Recipient-side hybrid decryption:
  # RSA-OAEP recovers the AES key, then AES-256-GCM recovers the message.
  def self.decrypt_message(encrypted_data, recipient_private_key_pem)
    ciphertext = Base64.strict_decode64(encrypted_data.fetch(:ciphertext) { encrypted_data.fetch("ciphertext") })
    encrypted_key = Base64.strict_decode64(encrypted_data.fetch(:encrypted_key) { encrypted_data.fetch("encrypted_key") })
    nonce = Base64.strict_decode64(encrypted_data.fetch(:nonce) { encrypted_data.fetch("nonce") })
    auth_tag = Base64.strict_decode64(encrypted_data.fetch(:auth_tag) { encrypted_data.fetch("auth_tag") })

    rsa_private_key = OpenSSL::PKey::RSA.new(recipient_private_key_pem)
    aes_key = rsa_private_key.private_decrypt(encrypted_key, OpenSSL::PKey::RSA::PKCS1_OAEP_PADDING)

    cipher = OpenSSL::Cipher.new("aes-256-gcm")
    cipher.decrypt
    cipher.key = aes_key
    cipher.iv = nonce
    cipher.auth_tag = auth_tag

    cipher.update(ciphertext) + cipher.final
  end

  def self.decrypt_message_with_password(encrypted_data, encrypted_private_key, password)
    recipient_private_key_pem = decrypt_private_key(encrypted_private_key, password)

    decrypt_message(encrypted_data, recipient_private_key_pem)
  end
end
