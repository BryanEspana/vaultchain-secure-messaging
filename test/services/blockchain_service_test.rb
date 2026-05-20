require "test_helper"

class BlockchainServiceTest < ActiveSupport::TestCase
  setup do
    Block.delete_all
    @service = BlockchainService.new(difficulty: 1)
  end

  test "genesis block is created and chain is valid" do
    Block.create_genesis!
    assert @service.valid_chain?
    assert_equal 1, @service.all_blocks.count
  end

  test "adding a block maintains a valid chain" do
    Block.create_genesis!
    @service.add_block!(message_hash: "hash123", sender_id: nil, recipient_id: nil)
    
    assert @service.valid_chain?
    assert_equal 2, @service.all_blocks.count
  end

  test "detects a corrupted chain when a block is modified" do
    Block.create_genesis!
    @service.add_block!(message_hash: "hash1", sender_id: nil, recipient_id: nil)
    @service.add_block!(message_hash: "hash2", sender_id: nil, recipient_id: nil)
    
    assert @service.valid_chain?

    # Tamper with the second block
    block_to_tamper = @service.all_blocks.order(:index)[1]
    block_to_tamper.update_column(:message_hash, "tampered_hash")

    assert_not @service.valid_chain?
  end
end
