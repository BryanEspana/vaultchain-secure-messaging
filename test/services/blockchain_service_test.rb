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

  test "each block previous_hash matches block_hash of prior block" do
    Block.create_genesis!
    @service.add_block!(
      message_hash: Digest::SHA256.hexdigest("mensaje uno"),
      sender_id: nil, recipient_id: nil
    )
    @service.add_block!(
      message_hash: Digest::SHA256.hexdigest("mensaje dos"),
      sender_id: nil, recipient_id: nil
    )

    blocks = @service.all_blocks.to_a

    assert_equal blocks[0].block_hash, blocks[1].previous_hash,
      "Block 1 previous_hash debe coincidir con block_hash del genesis"
    assert_equal blocks[1].block_hash, blocks[2].previous_hash,
      "Block 2 previous_hash debe coincidir con block_hash del bloque 1"
    assert @service.valid_chain?, "Cadena debe ser valida"
  end

  test "altering a message_hash in a block breaks chain integrity" do
    msg1_hash = Digest::SHA256.hexdigest("Hola Bryan, mensaje confidencial")
    msg2_hash = Digest::SHA256.hexdigest("Datos sensibles del segundo mensaje")

    Block.create_genesis!
    bloque1 = @service.add_block!(message_hash: msg1_hash, sender_id: nil, recipient_id: nil)
    bloque2 = @service.add_block!(message_hash: msg2_hash, sender_id: nil, recipient_id: nil)

    assert @service.valid_chain?, "Cadena debe ser valida antes de manipulacion"

    hash_original_bloque1  = bloque1.block_hash
    previous_hash_bloque2  = bloque2.previous_hash
    assert_equal hash_original_bloque1, previous_hash_bloque2,
      "Enlace genesis→bloque1 debe estar correcto antes del ataque"

    bloque1.update_columns(
      message_hash: Digest::SHA256.hexdigest("MENSAJE FALSO INYECTADO")
    )

    assert_not @service.valid_chain?,
      "Cadena debe ser INVALIDA despues de alterar message_hash del bloque 1"

    bloque1.reload
    assert_not_equal bloque1.compute_hash(bloque1.nonce), bloque1.block_hash,
      "compute_hash recalculado no debe coincidir con block_hash almacenado"
  end
end
