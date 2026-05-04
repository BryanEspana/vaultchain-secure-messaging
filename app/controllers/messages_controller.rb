class MessagesController < ApplicationController
  def index
    # Returns messages where the user is either the sender or the recipient
    user_id = params[:user_id]
    messages = Message.where("sender_id = ? OR recipient_id = ?", user_id, user_id).order(created_at: :desc)
    
    render json: { messages: messages }, status: :ok
  end

  def create
    # TODO: MessageEncryptionService - Logic for hybrid encryption or decryption simulation
    # If the architecture is strictly E2EE, the client sends ciphertext and encrypted_key.
    # The API just stores it.
    
    message = Message.new(message_params)
    
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
