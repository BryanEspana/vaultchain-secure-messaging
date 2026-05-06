class CreateGroupsAndMembers < ActiveRecord::Migration[7.2]
  def change
    create_table :groups, id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
      t.string :name, null: false
      t.uuid :creator_id, null: false
      t.timestamps
    end

    add_index :groups, :creator_id
    add_foreign_key :groups, :users, column: :creator_id

    create_table :group_members, id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
      t.uuid :group_id, null: false
      t.uuid :user_id, null: false
      t.timestamps
    end

    add_index :group_members, :group_id
    add_index :group_members, :user_id
    add_index :group_members, [:group_id, :user_id], unique: true
    add_foreign_key :group_members, :groups, column: :group_id
    add_foreign_key :group_members, :users, column: :user_id
  end
end
