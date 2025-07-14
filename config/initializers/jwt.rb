# JWT Configuration
module JwtConfig
  SECRET_KEY = Rails.application.credentials.secret_key_base || Rails.application.secret_key_base

  EXPIRATION_TIME = 24.hours

  ALGORITHM = 'HS256'

  def self.encode(payload)
    payload[:exp] = EXPIRATION_TIME.from_now.to_i
    JWT.encode(payload, SECRET_KEY, ALGORITHM)
  end

  def self.decode(token)
    JWT.decode(token, SECRET_KEY, true, { algorithm: ALGORITHM })[0]
  rescue JWT::DecodeError
    nil
  end

  def self.expired?(token)
    decoded = decode(token)
    return true unless decoded
    
    Time.at(decoded['exp']) < Time.current
  rescue
    true
  end

  def self.user_from_token(token)
    User.decode_jwt_token(token)
  rescue
    nil
  end

  def self.valid_token?(token)
    return false unless token
    
    decoded = decode(token)
    return false unless decoded
    
    required_fields = ['user_id', 'token_version', 'exp']
    required_fields.all? { |field| decoded.key?(field) }
  rescue
    false
  end
end 
