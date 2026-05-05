class AuthController < ApplicationController
  def register
    user = User.new(user_params)

    # Generate RSA keys and encrypt private key with AES
    crypto_keys = CryptoService.generate_keys(user_params[:password])
    user.public_key = crypto_keys[:public_key]
    user.encrypted_private_key = crypto_keys[:encrypted_private_key]

    if user.save
      render json: { message: "Usuario registrado exitosamente", user_id: user.id }, status: :created
    else
      render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def login
    user = User.find_by(email: params[:email])

    # authenticate usa el has_secure_password (bcrypt) ya configurado
    if user&.authenticate(params[:password])
      token = JsonWebToken.encode(user_id: user.id)
      render json: {
        message: "Login exitoso",
        token: token,
        user_id: user.id,
        encrypted_private_key: user.encrypted_private_key
      }, status: :ok
    else
      render json: { error: "Credenciales inválidas" }, status: :unauthorized
    end
  end

  private

  def user_params
    params.permit(:email, :display_name, :password, :password_confirmation)
  end
end
