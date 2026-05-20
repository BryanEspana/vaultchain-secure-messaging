class BlockchainService
  def initialize(difficulty: 2)
    @difficulty = difficulty
  end

  # returns all blocks in order of index
  def all_blocks
    Block.order(:index)
  end

  # returns the last block
  def last_block
    all_blocks.last
  end

  # creates a new block to the chain
  def add_block!(message_hash:, sender_id: nil, recipient_id: nil)
    next_index = (last_block&.index || -1) + 1
    b = Block.new(
<<<<<<< HEAD
      index: next_index,
      timestamp: Time.now.utc,
      sender_id: sender_id,
      recipient_id: recipient_id,
      message_hash: message_hash,
      previous_hash: (last_block&.hash || ('0' * 64)), # initialize root block if there's none before
      nonce: 0
    )
    # compute hash deterministically and persist
    b.save!
    b
  end

  # Verifies the chain: indexes contiguous, previous_hash links, and recomputed hashes match
  # If they match the block is chained
=======
      index:         next_index,
      timestamp:     Time.now.utc,
      sender_id:     sender_id,
      recipient_id:  recipient_id,
      message_hash:  message_hash,
      previous_hash: (last_block&.block_hash || ('0' * 64)),
      nonce:         0
    )
    b.mine!(difficulty: @difficulty)
    b
  end

>>>>>>> feature/implement_blockchain
  def valid_chain?
    prev = nil
    all_blocks.each_with_index do |blk, idx|
      return false unless blk.index == idx
      return false if prev && blk.previous_hash != prev.block_hash
      return false if blk.compute_hash(blk.nonce) != blk.block_hash
      prev = blk
    end
    true
  end
end
