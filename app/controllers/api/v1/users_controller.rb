class Api::V1::UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :require_admin!, except: [:show, :update, :index]
  before_action :set_user, only: [:show, :update, :destroy, :activate, :deactivate, :invalidate_tokens]
  before_action :check_user_access, only: [:show, :update]

  def index
    search_result = execute_search_service
    render_success(search_result.to_h)
  end

  def show
    render_success({ user: @user.as_json_response })
  end

  def create
    user = build_user
    
    if user.save
      render_user_created(user)
    else
      render_validation_errors(user.errors.full_messages)
    end
  end

  def update
    if update_user
      render_user_updated
    else
      render_validation_errors(@user.errors.full_messages)
    end
  end

  def destroy
    @user.destroy
    render_success({}, 'User deleted successfully')
  end

  def activate
    activate_user
    render_user_activated
  end

  def deactivate
    deactivate_user
    render_user_deactivated
  end

  def invalidate_tokens
    invalidate_user_tokens
    render_tokens_invalidated
  end

  private

  def execute_search_service
    Users::SearchService.new(search_params).call
  end

  def search_params
    params.permit(:q, :name, :email, :role, :active, :sort_by, :order, :page, :per_page)
  end

  def build_user
    User.new(user_params)
  end

  def update_user
    update_params = determine_update_params
    @user.update(update_params)
  end

  def determine_update_params
    return user_params if current_user.admin?
    
    user_params.except(:role, :active)
  end

  def activate_user
    @user.update(active: true)
  end

  def deactivate_user
    @user.update(active: false)
    @user.invalidate_all_tokens!
  end

  def invalidate_user_tokens
    @user.invalidate_all_tokens!
  end

  def set_user
    @user = find_user
  end

  def find_user
    User.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_not_found('User not found')
  end

  def check_user_access
    render_forbidden unless user_has_access?
  end

  def user_has_access?
    current_user.admin? || current_user.id == @user.id
  end

  def user_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation, :role, :active)
  end

  def render_user_created(user)
    render_created(
      { user: user.as_json_response },
      'User created successfully'
    )
  end

  def render_user_updated
    render_success(
      { user: @user.as_json_response },
      'User updated successfully'
    )
  end

  def render_user_activated
    render_success(
      { user: @user.as_json_response },
      'User activated successfully'
    )
  end

  def render_user_deactivated
    render_success(
      { user: @user.as_json_response },
      'User deactivated successfully. All user tokens have been invalidated.'
    )
  end

  def render_tokens_invalidated
    render_success(
      { user: @user.as_json_response },
      'All tokens for this user have been invalidated. User will need to login again.'
    )
  end
end 