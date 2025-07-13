class Api::V1::AuthenticationController < ApplicationController
  before_action :authenticate_user!, except: [:login]
  
  def login
    user = User.find_by(email: params[:email])
    
    if user && user.valid_password?(params[:password])
      if user.active?
        token = user.generate_jwt_token
        render json: {
          success: true,
          token: token,
          user: {
            id: user.id,
            name: user.name,
            email: user.email,
            role: user.role
          }
        }, status: :ok
      else
        render json: {
          success: false,
          error: 'Account is inactive'
        }, status: :unauthorized
      end
    else
      render json: {
        success: false,
        error: 'Invalid credentials'
      }, status: :unauthorized
    end
  end

  def refresh_token
    token = current_user.generate_jwt_token
    render json: {
      success: true,
      token: token,
      user: {
        id: current_user.id,
        name: current_user.name,
        email: current_user.email,
        role: current_user.role
      }
    }, status: :ok
  end

  def logout
    # For JWT, we don't need to do anything server-side
    # The client should just discard the token
    render json: {
      success: true,
      message: 'Successfully logged out'
    }, status: :ok
  end

  def profile
    render json: {
      success: true,
      user: {
        id: current_user.id,
        name: current_user.name,
        email: current_user.email,
        role: current_user.role,
        active: current_user.active
      }
    }, status: :ok
  end

  private

  def authenticate_user!
    token = request.headers['Authorization']&.split(' ')&.last
    return render_unauthorized unless token

    begin
      decoded_token = JWT.decode(token, Rails.application.credentials.secret_key_base)[0]
      @current_user = User.find(decoded_token['user_id'])
      
      unless @current_user&.active?
        render_unauthorized
      end
    rescue JWT::DecodeError, ActiveRecord::RecordNotFound
      render_unauthorized
    end
  end

  def current_user
    @current_user
  end

  def render_unauthorized
    render json: {
      success: false,
      error: 'Unauthorized'
    }, status: :unauthorized
  end
end 