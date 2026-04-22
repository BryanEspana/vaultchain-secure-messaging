class UsersController < ApplicationController
  def key
    user = User.find_by(id: params[:id])

    if user
      if user.public_key.present?
        render json: { public_key: user.public_key }, status: :ok
      else
        render json: { error: "Llave pública no encontrada para este usuario" }, status: :not_found
      end
    else
      render json: { error: "Usuario no encontrado" }, status: :not_found
    end
  end
end
