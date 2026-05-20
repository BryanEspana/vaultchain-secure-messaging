class RenameHashColumnInBlocks < ActiveRecord::Migration[7.2]
  def change
    rename_column :blocks, :hash, :block_hash
  end
end
