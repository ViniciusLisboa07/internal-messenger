class Api::V1::AuthenticationController < ApplicationController
  before_action :authenticate_user!, except: [:login]
  
  def login
    user = User.find_by(email: params[:email])
    
    if user && user.valid_password?(params[:password])
      if user.active?
        token = user.generate_jwt_token
        render_success(
          {
            token: token,
            user: user.as_json_response
          },
          'Login successful'
        )
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
    render_success(
      {
        token: token,
        user: current_user.as_json_response
      },
      'Token refreshed successfully'
    )
  end

  def logout
    # For JWT, we don't need to do anything server-side
    # The client should just discard the token
    render_success({}, 'Successfully logged out')
  end

  def profile
    render_success(
      {
        user: current_user.as_json_response
      }
    )
  end

  def update_profile
    if current_user.update(profile_params)
      render_success(
        {
          user: current_user.as_json_response
        },
        'Profile updated successfully'
      )
    else
      render_validation_errors(current_user.errors.full_messages)
    end
  end

  private

  def profile_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation)
  end
end 