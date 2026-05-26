class AuthController < ApplicationController
  def register
    user = User.new(user_params)

    # Generate RSA keys and encrypt private key with AES
    crypto_keys = CryptoService.generate_keys(user_params[:password])
    user.public_key = crypto_keys[:public_key]
    user.encrypted_private_key = crypto_keys[:encrypted_private_key]

    if crypto_keys[:public_key].present? && user.save
      render json: { message: "Usuario registrado exitosamente", user_id: user.id }, status: :created
    else
      errors = user.errors.full_messages
      errors << "No se pudieron generar las llaves criptográficas" if crypto_keys[:public_key].blank?
      render json: { errors: errors }, status: :unprocessable_entity
    end
  end

  def login
    user = User.find_by(email: params[:email])

    # authenticate usa el has_secure_password (bcrypt) ya configurado
    if user&.authenticate(params[:password])
      if user.totp_secret.present?
        temp_token = JsonWebToken.encode(user_id: user.id, mfa_pending: true)
        render json: {
          message: "MFA requerido",
          mfa_required: true,
          temp_token: temp_token
        }, status: :ok
      else
        token = JsonWebToken.encode(user_id: user.id)
        render json: {
          message: "Login exitoso",
          token: token,
          user_id: user.id,
          public_key: user.public_key,
          encrypted_private_key: user.encrypted_private_key
        }, status: :ok
      end
    else
      render json: { error: "Credenciales inválidas" }, status: :unauthorized
    end
  end

  def mfa_enable
    user = User.find_by(id: params[:user_id])
    return render json: { error: "Usuario no encontrado" }, status: :not_found unless user

    user.totp_secret = ROTP::Base32.random
    user.save!

    totp = ROTP::TOTP.new(user.totp_secret, issuer: "VaultChain")
    qr_code = RQRCode::QRCode.new(totp.provisioning_uri(user.email))
    qr_base64 = Base64.strict_encode64(qr_code.as_png(size: 200).to_blob)

    render json: {
      message: "MFA habilitado correctamente",
      totp_secret: user.totp_secret,
      qr_code_base64: qr_base64
    }, status: :ok
  end

  def mfa_verify
    decoded = JsonWebToken.decode(params[:temp_token])
    return render json: { error: "Token temporal inválido" }, status: :unauthorized unless decoded

    user = User.find_by(id: decoded[:user_id])
    return render json: { error: "Usuario no encontrado" }, status: :not_found unless user

    totp = ROTP::TOTP.new(user.totp_secret, issuer: "VaultChain")
    if totp.verify(params[:code], drift_behind: 15)
      token = JsonWebToken.encode(user_id: user.id)
      render json: {
        message: "Login exitoso",
        token: token,
        user_id: user.id,
        public_key: user.public_key,
        encrypted_private_key: user.encrypted_private_key
      }, status: :ok
    else
      render json: { error: "Código MFA inválido" }, status: :unauthorized
    end
  end

  private

  def user_params
    params.permit(:email, :display_name, :password, :password_confirmation)
  end
end
