class CreateUsers < ActiveRecord::Migration[7.2]
  def change
    create_table :users, id: :uuid do |t|
      t.string :email, null: false
      t.string :display_name
      t.string :password_digest, null: false
      t.text :public_key
      t.text :encrypted_private_key
      t.string :totp_secret

      t.timestamps
    end
    add_index :users, :email, unique: true
  end
end
