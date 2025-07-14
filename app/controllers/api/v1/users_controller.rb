class Api::V1::UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :require_admin!, except: [:show, :update]
  before_action :set_user, only: [:show, :update, :destroy, :activate, :deactivate]
  before_action :check_user_access, only: [:show, :update]

  def index
    users = User.all.order(:name)
    render_success(
      {
        users: users.map(&:as_json_response)
      }
    )
  end

  def show
    render_success(
      {
        user: @user.as_json_response
      }
    )
  end

  def create
    user = User.new(user_params)
    
    if user.save
      render_created(
        {
          user: user.as_json_response
        },
        'User created successfully'
      )
    else
      render_validation_errors(user.errors.full_messages)
    end
  end

  def update
    update_params = user_params
    unless current_user.admin?
      update_params = update_params.except(:role, :active)
    end

    if @user.update(update_params)
      render_success(
        {
          user: @user.as_json_response
        },
        'User updated successfully'
      )
    else
      render_validation_errors(@user.errors.full_messages)
    end
  end

  def destroy
    @user.destroy
    render_success({}, 'User deleted successfully')
  end

  def activate
    @user.update(active: true)
    render_success(
      {
        user: @user.as_json_response
      },
      'User activated successfully'
    )
  end

  def deactivate
    @user.update(active: false)
    render_success(
      {
        user: @user.as_json_response
      },
      'User deactivated successfully'
    )
  end

  private

  def set_user
    @user = User.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_not_found('User not found')
  end

  def check_user_access
    unless current_user.admin? || current_user.id == @user.id
      render_forbidden
    end
  end

  def user_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation, :role, :active)
  end
end 