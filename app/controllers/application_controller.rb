class ApplicationController < ActionController::API
  attr_reader :current_user

  private

  def authenticate_user!
    token = extract_token_from_header
    return render_unauthorized('No authorization token provided') unless token

    unless JwtConfig.valid_token?(token)
      return render_unauthorized('Invalid token format')
    end

    @current_user = JwtConfig.user_from_token(token)
    
    if @current_user.nil?
      return render_unauthorized('Token is invalid or has been revoked')
    end
    
    unless @current_user.active?
      return render_unauthorized('Account is inactive')
    end
  end

  def extract_token_from_header
    auth_header = request.headers['Authorization']
    return nil unless auth_header

    token = auth_header.split(' ').last
    token if auth_header.start_with?('Bearer ')
  end

  def require_admin!
    unless current_user&.admin?
      render json: {
        success: false,
        error: 'Admin access required'
      }, status: :forbidden
    end
  end

  def render_unauthorized(message = 'Unauthorized')
    render json: {
      success: false,
      error: message
    }, status: :unauthorized
  end

  def render_forbidden
    render json: {
      success: false,
      error: 'Forbidden'
    }, status: :forbidden
  end

  def render_not_found(message = 'Resource not found')
    render json: {
      success: false,
      error: message
    }, status: :not_found
  end

  def render_validation_errors(errors)
    render json: {
      success: false,
      errors: errors.is_a?(Array) ? errors : [errors]
    }, status: :unprocessable_entity
  end

  def render_success(data = {}, message = nil)
    response = { success: true }
    response[:message] = message if message
    response.merge!(data)
    render json: response, status: :ok
  end

  def render_created(data = {}, message = 'Resource created successfully')
    response = { success: true, message: message }
    response.merge!(data)
    render json: response, status: :created
  end
end
