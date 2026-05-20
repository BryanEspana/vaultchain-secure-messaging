require 'digest'

class Block < ApplicationRecord
  self.primary_key = 'id'

  belongs_to :sender, class_name: 'User', foreign_key: 'sender_id', optional: true
  belongs_to :recipient, class_name: 'User', foreign_key: 'recipient_id', optional: true

  validates :index, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :timestamp, presence: true
  validates :message_hash, presence: true
  validates :previous_hash, presence: true
  validates :nonce, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :block_hash, presence: true

  def compute_hash(nonce_override = nil)
    n  = nonce_override.nil? ? nonce : nonce_override
    ts = timestamp.respond_to?(:to_i) ? timestamp.to_i : timestamp
    data = [index, ts, message_hash, previous_hash, n].join
    Digest::SHA256.hexdigest(data)
  end

  def mine!(difficulty: 2, max_attempts: 10_000)
    target_prefix = '0' * difficulty
    self.nonce = 0
    loop do
      self.block_hash = compute_hash(nonce)
      break if block_hash.start_with?(target_prefix)
      self.nonce += 1
      raise "Failed to mine block after #{max_attempts} attempts" if nonce > max_attempts
    end
    save!
  end

  def self.create_genesis!(attrs = {})
    defaults = {
      index:         0,
      timestamp:     Time.at(0).utc,
      sender_id:     nil,
      recipient_id:  nil,
      message_hash:  '0' * 64,
      previous_hash: '0' * 64,
      nonce:         0
    }
    b = new(defaults.merge(attrs))
    b.block_hash = b.compute_hash(b.nonce)
    b.save!
    b
  end
end
