class Api::V1::RegistrationsController < ApplicationController
  def create
    user = User.new(user_params)
    
    if user.save
      token = user.generate_jwt_token
      render_created(
        {
          token: token,
          user: user.as_json_response
        },
        'User registered successfully'
      )
    else
      render_validation_errors(user.errors.full_messages)
    end
  end

  private

  def user_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation, :role)
  end
end 