class CreateMessages < ActiveRecord::Migration[7.2]
  def change
    create_table :messages, id: :uuid do |t|
      t.uuid :sender_id, null: false
      t.uuid :recipient_id
      t.uuid :group_id
      t.text :ciphertext
      t.text :encrypted_key
      t.string :nonce
      t.string :auth_tag
      t.text :signature

      t.timestamps
    end

    add_index :messages, :sender_id
    add_index :messages, :recipient_id
    add_index :messages, :group_id

    add_foreign_key :messages, :users, column: :sender_id
    add_foreign_key :messages, :users, column: :recipient_id
  end
end
