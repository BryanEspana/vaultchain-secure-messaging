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
    iv = cipher.random_iv

    encrypted = cipher.update(private_key_pem) + cipher.final
    auth_tag = cipher.auth_tag

    # Combine salt, IV, auth_tag, and encrypted data, then Base64 encode
    combined = salt + iv + auth_tag + encrypted
    Base64.strict_encode64(combined)
  end

  # Decrypt private key (for future use when retrieving keys)
  def self.decrypt_private_key(encrypted_data, password)
    combined = Base64.strict_decode64(encrypted_data)

    # Extract salt (first 16 bytes), IV (next 16 bytes), auth_tag (next 16 bytes), and encrypted data
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
end
