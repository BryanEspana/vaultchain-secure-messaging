class CreateBlocks < ActiveRecord::Migration[7.0]
  def change
    create_table :blocks, id: :uuid do |t|
      t.integer :index, null: false
      t.datetime :timestamp, null: false
      t.uuid :sender_id, null: true
      t.uuid :recipient_id, null: true
      t.string :message_hash, null: false
      t.string :previous_hash, null: false
      t.integer :nonce, null: false, default: 0
      t.string :hash, null: false

      t.timestamps
    end

    add_index :blocks, :index, unique: true
    add_index :blocks, :hash, unique: true
    add_index :blocks, :previous_hash
  end
end
