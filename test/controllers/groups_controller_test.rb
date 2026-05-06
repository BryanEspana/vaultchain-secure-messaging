require "test_helper"

class GroupsControllerTest < ActionDispatch::IntegrationTest
  test "group creation endpoint is prepared but not implemented" do
    post "/groups"

    assert_response :not_implemented
    assert_equal "Endpoint de creación de grupos preparado. Falta lógica criptográfica.", response.parsed_body["message"]
  end
end
