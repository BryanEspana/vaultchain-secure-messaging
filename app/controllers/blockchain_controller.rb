class BlockchainController < ApplicationController
  def verify
    service = BlockchainService.new
    valid = service.valid_chain?
    render json: {
      valid: valid,
      block_count: service.all_blocks.count
    }, status: :ok
  end
end
