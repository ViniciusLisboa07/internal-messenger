require 'rails_helper'

RSpec.describe 'Api::V1::Authentication', type: :request do
  describe 'POST /api/v1/login' do
    let(:user) { create(:user, email: 'test@example.com', password: 'password123') }
    let(:valid_credentials) do
      {
        email: user.email,
        password: 'password123'
      }
    end

    context 'with valid credentials' do
      it 'returns success response with token and user data' do
        post '/api/v1/login', params: valid_credentials

        expect_success_response
        expect(json_response).to include('token', 'user')
        expect(json_response['user']['email']).to eq(user.email)
        expect(json_response['user']['name']).to eq(user.name)
        expect(json_response['user']['role']).to eq(user.role)
        expect(json_response['user']['active']).to eq(user.active)
      end

      it 'returns correct user data structure' do
        post '/api/v1/login', params: valid_credentials

        user_data = json_response['user']
        expect(user_data).to include(
          'id', 'name', 'email', 'role', 'active', 'created_at', 'updated_at'
        )
        expect(user_data).not_to include('password', 'encrypted_password', 'token_version')
      end

      it 'generates a valid JWT token' do
        post '/api/v1/login', params: valid_credentials

        token = json_response['token']
        expect(token).to be_a(String)
        expect(token.split('.').length).to eq(3)

        decoded_user = User.decode_jwt_token(token)
        expect(decoded_user).to eq(user)
      end
    end

    context 'with invalid credentials' do
      it 'returns unauthorized for wrong password' do
        post '/api/v1/login', params: {
          email: user.email,
          password: 'wrong_password'
        }

        expect_unauthorized_response
        expect(json_response['error']).to eq('Invalid credentials')
      end

      it 'returns unauthorized for non-existent email' do
        post '/api/v1/login', params: {
          email: 'nonexistent@example.com',
          password: 'password123'
        }

        expect_unauthorized_response
        expect(json_response['error']).to eq('Invalid credentials')
      end

      it 'returns unauthorized for inactive user' do
        inactive_user = create(:inactive_user, email: 'inactive@example.com', password: 'password123')
        
        post '/api/v1/login', params: {
          email: inactive_user.email,
          password: 'password123'
        }

        expect_unauthorized_response
        expect(json_response['error']).to eq('Account is inactive')
      end
    end

    context 'with missing parameters' do
      it 'returns unauthorized for missing email' do
        post '/api/v1/login', params: { password: 'password123' }

        expect_unauthorized_response
        expect(json_response['error']).to eq('Invalid credentials')
      end

      it 'returns unauthorized for missing password' do
        post '/api/v1/login', params: { email: user.email }

        expect_unauthorized_response
        expect(json_response['error']).to eq('Invalid credentials')
      end
    end
  end

  describe 'POST /api/v1/refresh_token' do
    let(:user) { create(:user) }

    context 'with valid token' do
      it 'returns new token and user data' do
        token = auth_token_for(user)
        
        post '/api/v1/refresh_token', headers: { 'Authorization' => "Bearer #{token}" }

        puts "Response status: #{response.status}"
        puts "Response body: #{response.body}"

        expect_success_response
        expect(json_response).to include('token', 'user')
        expect(json_response['user']['id']).to eq(user.id)
      end

      it 'invalidates previous tokens' do
        original_token = user.generate_jwt_token
        original_version = user.token_version
        
        token = auth_token_for(user)
        post '/api/v1/refresh_token', headers: { 'Authorization' => "Bearer #{token}" }

        expect(User.decode_jwt_token(original_token)).to be_nil
        
        expect(user.reload.token_version).to eq(original_version + 1)
      end

      it 'generates a new valid token' do
        token = auth_token_for(user)
        
        post '/api/v1/refresh_token', headers: { 'Authorization' => "Bearer #{token}" }

        new_token = json_response['token']
        decoded_user = User.decode_jwt_token(new_token)
        expect(decoded_user).to eq(user)
      end
    end

    context 'without authentication' do
      it 'returns unauthorized' do
        post '/api/v1/refresh_token'

        expect_unauthorized_response
      end
    end

    context 'with invalid token' do
      it 'returns unauthorized' do
        post '/api/v1/refresh_token', headers: { 'Authorization' => 'Bearer invalid_token' }

        expect_unauthorized_response
      end
    end
  end

  describe 'POST /api/v1/logout' do
    let(:user) { create(:user) }

    context 'with valid authentication' do
      it 'returns success message' do
        token = auth_token_for(user)
        
        post '/api/v1/logout', headers: { 'Authorization' => "Bearer #{token}" }

        expect_success_response
        expect(json_response['message']).to include('Successfully logged out')
      end

      it 'invalidates all user tokens' do
        original_token = user.generate_jwt_token
        original_version = user.token_version
        
        token = auth_token_for(user)
        post '/api/v1/logout', headers: { 'Authorization' => "Bearer #{token}" }

        expect(User.decode_jwt_token(original_token)).to be_nil
        
        expect(user.reload.token_version).to eq(original_version + 1)
      end

      it 'prevents further access with old token' do
        original_token = user.generate_jwt_token
        
        token = auth_token_for(user)
        post '/api/v1/logout', headers: { 'Authorization' => "Bearer #{token}" }

        get '/api/v1/profile', headers: { 'Authorization' => "Bearer #{original_token}" }

        expect_unauthorized_response
      end
    end

    context 'without authentication' do
      it 'returns unauthorized' do
        post '/api/v1/logout'

        expect_unauthorized_response
      end
    end
  end

  describe 'GET /api/v1/profile' do
    let(:user) { create(:user) }

    context 'with valid authentication' do
      it 'returns user profile data' do
        token = auth_token_for(user)
        
        get '/api/v1/profile', headers: { 'Authorization' => "Bearer #{token}" }

        expect_success_response
        expect(json_response).to include('user')
        expect(json_response['user']['id']).to eq(user.id)
        expect(json_response['user']['email']).to eq(user.email)
        expect(json_response['user']['name']).to eq(user.name)
      end

      it 'returns correct user data structure' do
        token = auth_token_for(user)
        
        get '/api/v1/profile', headers: { 'Authorization' => "Bearer #{token}" }

        user_data = json_response['user']
        expect(user_data).to include(
          'id', 'name', 'email', 'role', 'active', 'created_at', 'updated_at'
        )
        expect(user_data).not_to include('password', 'encrypted_password', 'token_version')
      end
    end

    context 'without authentication' do
      it 'returns unauthorized' do
        get '/api/v1/profile'

        expect_unauthorized_response
      end
    end

    context 'with invalid token' do
      it 'returns unauthorized' do
        get '/api/v1/profile', headers: { 'Authorization' => 'Bearer invalid_token' }

        expect_unauthorized_response
      end
    end
  end

  describe 'PUT /api/v1/profile' do
    let(:user) { create(:user, name: 'Original Name', email: 'original@example.com') }

    context 'with valid authentication' do
      it 'updates user profile successfully' do
        token = auth_token_for(user)
        update_params = {
          user: {
            name: 'Updated Name',
            email: 'updated@example.com'
          }
        }

        put '/api/v1/profile', params: update_params, headers: { 'Authorization' => "Bearer #{token}" }

        expect_success_response
        expect(json_response['message']).to eq('Profile updated successfully')
        expect(json_response['user']['name']).to eq('Updated Name')
        expect(json_response['user']['email']).to eq('updated@example.com')
      end

      it 'updates password when provided' do
        token = auth_token_for(user)
        update_params = {
          user: {
            password: 'newpassword123',
            password_confirmation: 'newpassword123'
          }
        }

        put '/api/v1/profile', params: update_params, headers: { 'Authorization' => "Bearer #{token}" }

        expect_success_response
        expect(user.reload.valid_password?('newpassword123')).to be true
      end

      it 'validates password confirmation' do
        token = auth_token_for(user)
        update_params = {
          user: {
            password: 'newpassword123',
            password_confirmation: 'differentpassword'
          }
        }

        put '/api/v1/profile', params: update_params, headers: { 'Authorization' => "Bearer #{token}" }

        expect_error_response
        expect(json_response['errors']).to include("Password confirmation doesn't match Password")
      end

      it 'validates email uniqueness' do
        token = auth_token_for(user)
        other_user = create(:user, email: 'taken@example.com')
        
        update_params = {
          user: {
            email: 'taken@example.com'
          }
        }

        put '/api/v1/profile', params: update_params, headers: { 'Authorization' => "Bearer #{token}" }

        expect_error_response
        expect(json_response['errors']).to include('Email has already been taken')
      end

      it 'validates name length' do
        token = auth_token_for(user)
        update_params = {
          user: {
            name: 'A' # Too short
          }
        }

        put '/api/v1/profile', params: update_params, headers: { 'Authorization' => "Bearer #{token}" }

        expect_error_response
        expect(json_response['errors']).to include('Name is too short (minimum is 2 characters)')
      end
    end

    context 'without authentication' do
      it 'returns unauthorized' do
        put '/api/v1/profile', params: { user: { name: 'New Name' } }

        expect_unauthorized_response
      end
    end
  end

  describe 'token validation edge cases' do
    let(:user) { create(:user) }

    it 'handles expired tokens' do
      token = JWT.encode(
        {
          user_id: user.id,
          email: user.email,
          role: user.role,
          token_version: user.token_version,
          exp: 1.second.ago.to_i
        },
        Rails.application.credentials.secret_key_base
      )

      get '/api/v1/profile', headers: { 'Authorization' => "Bearer #{token}" }

      expect_unauthorized_response
    end

    it 'handles tokens with wrong user_id' do
      token = JWT.encode(
        {
          user_id: 99999,
          email: user.email,
          role: user.role,
          token_version: user.token_version
        },
        Rails.application.credentials.secret_key_base
      )

      get '/api/v1/profile', headers: { 'Authorization' => "Bearer #{token}" }

      expect_unauthorized_response
    end

    it 'handles tokens with wrong token_version' do
      token = user.generate_jwt_token
      user.increment!(:token_version)

      get '/api/v1/profile', headers: { 'Authorization' => "Bearer #{token}" }

      expect_unauthorized_response
    end
  end
end 