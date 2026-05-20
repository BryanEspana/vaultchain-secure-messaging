require "openssl"
require "base64"

class DigitalSignatureService
  # Firma un mensaje original utilizando la llave privada del remitente.
  def self.sign(message, private_key_pem)
    private_key = OpenSSL::PKey::RSA.new(private_key_pem)
    digest = OpenSSL::Digest.new("SHA256")
    signature = private_key.sign(digest, message)
    Base64.strict_encode64(signature)
  end

  # Verifica la firma de un mensaje utilizando la llave pública del remitente.
  def self.verify(message, signature_base64, public_key_pem)
    return false if signature_base64.blank? || public_key_pem.blank? || message.nil?

    public_key = OpenSSL::PKey::RSA.new(public_key_pem)
    digest = OpenSSL::Digest.new("SHA256")
    raw_signature = Base64.strict_decode64(signature_base64)
    public_key.verify(digest, raw_signature, message)
  rescue OpenSSL::PKey::PKeyError, ArgumentError => e
    false
  end
end
