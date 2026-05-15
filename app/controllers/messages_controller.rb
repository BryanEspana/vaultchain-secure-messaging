class MessagesController < ApplicationController
  def index
    user_id = params[:user_id]
    other_user_id = params[:other_user_id]
    
    if other_user_id.present?
      # Filtramos la conversación específica entre dos usuarios
      messages = Message.where(
        "(sender_id = ? AND recipient_id = ?) OR (sender_id = ? AND recipient_id = ?)",
        user_id, other_user_id, other_user_id, user_id
      ).order(created_at: :asc)
    else
      # Fallback: todos los mensajes del usuario (sent o received)
      messages = Message.where("sender_id = ? OR recipient_id = ?", user_id, user_id).order(created_at: :asc)
    end

    render json: { messages: messages }, status: :ok
  end

  def group_index
    group_id = params[:group_id]
    messages = Message.where(group_id: group_id).order(created_at: :asc)
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

  def verify
    message = Message.find(params[:id])
    sender = message.sender
    
    if sender.nil? || sender.public_key.blank?
      return render json: { error: "No se encontró la llave pública del remitente" }, status: :not_found
    end

    # La verificación requiere el texto plano. 
    # En un sistema E2EE real, esto lo haría el cliente.
    # Aquí lo exponemos como endpoint que recibe el plaintext para la tarea.
    plaintext = params[:plaintext]
    
    if plaintext.blank?
      return render json: { error: "Se requiere el texto plano para verificar la firma" }, status: :bad_request
    end

    is_valid = DigitalSignatureService.verify(plaintext, message.signature, sender.public_key)

    render json: { 
      valid: is_valid,
      message_id: message.id,
      sender: sender.display_name
    }, status: :ok
  end

  private

  def message_params
    params.permit(:sender_id, :recipient_id, :group_id, :ciphertext, :encrypted_key, :nonce, :auth_tag, :signature)
  end
end
