module AuthenticationHelper
  def auth_token_for(user)
    user.reload if user.persisted?
    user.generate_jwt_token
  end

  def login_user(attributes = {})
    user = create(:user, attributes)
    user
  end

  def login_admin(attributes = {})
    user = create(:admin_user, attributes)
    user
  end

  def json_response
    JSON.parse(response.body)
  end

  def expect_success_response
    expect(response).to have_http_status(:ok)
    expect(json_response['success']).to be true
  end

  def expect_error_response(status = :unprocessable_entity)
    expect(response).to have_http_status(status)
    expect(json_response['success']).to be false
  end

  def expect_unauthorized_response
    expect(response).to have_http_status(:unauthorized)
    expect(json_response['success']).to be false
  end

  def expect_forbidden_response
    expect(response).to have_http_status(:forbidden)
    expect(json_response['success']).to be false
  end

  def expect_not_found_response
    expect(response).to have_http_status(:not_found)
    expect(json_response['success']).to be false
  end
end 