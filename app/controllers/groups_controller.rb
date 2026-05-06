class GroupsController < ApplicationController
  def create
    creator_id = params[:creator_id]
    name = params[:name]
    member_ids = params[:member_ids] || []

    return render json: { error: "Nombre del grupo requerido" }, status: :unprocessable_entity if name.blank?
    return render json: { error: "Se requiere al menos un miembro" }, status: :unprocessable_entity if member_ids.empty?

    group = Group.new(name: name, creator_id: creator_id)

    unless group.save
      return render json: { errors: group.errors.full_messages }, status: :unprocessable_entity
    end

    # Add creator as member
    all_member_ids = ([creator_id] + member_ids).uniq
    all_member_ids.each do |uid|
      GroupMember.create!(group_id: group.id, user_id: uid)
    end

    # Return group with members and their public keys for client-side encryption
    members_with_keys = User.where(id: all_member_ids).map do |u|
      { id: u.id, display_name: u.display_name, public_key: u.public_key }
    end

    render json: {
      message: "Grupo creado exitosamente",
      group: { id: group.id, name: group.name, creator_id: group.creator_id },
      members: members_with_keys
    }, status: :created
  end

  def index
    user_id = params[:user_id]
    return render json: { error: "user_id requerido" }, status: :unprocessable_entity if user_id.blank?

    group_ids = GroupMember.where(user_id: user_id).pluck(:group_id)
    groups = Group.where(id: group_ids).map do |g|
      members = g.members.map { |m| { id: m.id, display_name: m.display_name } }
      { id: g.id, name: g.name, creator_id: g.creator_id, members: members }
    end

    render json: { groups: groups }, status: :ok
  end

  def members
    group = Group.find_by(id: params[:id])
    return render json: { error: "Grupo no encontrado" }, status: :not_found unless group

    members_with_keys = group.members.map do |u|
      { id: u.id, display_name: u.display_name, public_key: u.public_key }
    end

    render json: { members: members_with_keys }, status: :ok
  end
end
