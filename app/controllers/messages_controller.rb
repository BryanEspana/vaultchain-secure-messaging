class MessagesController < ApplicationController
  def index
    # Returns messages where the user is either the sender or the recipient
    user_id = params[:user_id]
    messages = Message.where("sender_id = ? OR recipient_id = ?", user_id, user_id).order(created_at: :desc)

    render json: { messages: messages }, status: :ok
  end

  def create
    # Simulate hybrid encryption on server side for E2EE
    if params[:plaintext].present?
      recipient = User.find(params[:recipient_id])
      encrypted_data = CryptoService.encrypt_message(params[:plaintext], recipient.public_key)

      message = Message.new(
        sender_id: params[:sender_id],
        recipient_id: params[:recipient_id],
        group_id: params[:group_id],
        **encrypted_data
      )
    else
      # Fallback: assume client sent encrypted data
      message = Message.new(message_params)
    end

    if message.save
      render json: { message: "Mensaje enviado exitosamente", message_id: message.id }, status: :created
    else
      render json: { errors: message.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def message_params
    params.permit(:sender_id, :recipient_id, :group_id, :ciphertext, :encrypted_key, :nonce, :auth_tag)
  end
end
