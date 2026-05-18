class BlockchainService
  # Simple in-memory / DB-backed blockchain helper service
  def initialize(difficulty: 2)
    @difficulty = difficulty
  end

  def all_blocks
    Block.order(:index)
  end

  def last_block
    all_blocks.last
  end

  def add_block!(message_hash:, sender_id: nil, recipient_id: nil)
    next_index = (last_block&.index || -1) + 1
    b = Block.new(
      index: next_index,
      timestamp: Time.now.utc,
      sender_id: sender_id,
      recipient_id: recipient_id,
      message_hash: message_hash,
      previous_hash: (last_block&.hash || ('0' * 64)),
      nonce: 0
    )
    # mine to meet difficulty
    b.mine!(difficulty: @difficulty)
    b
  end

  # Verifies the chain: indexes contiguous, previous_hash links, and recomputed hashes match
  def valid_chain?
    prev = nil
    all_blocks.each_with_index do |blk, idx|
      return false unless blk.index == idx
      return false if prev && blk.previous_hash != prev.hash
      return false if blk.compute_hash(blk.nonce) != blk.hash
      prev = blk
    end
    true
  end
end
