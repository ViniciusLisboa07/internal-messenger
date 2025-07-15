class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :trackable

  validates :name, presence: true, length: { minimum: 2, maximum: 50 }
  validates :email, presence: true, uniqueness: { case_sensitive: false }
  validates :role, inclusion: { in: %w[admin employee] }
  validates :active, inclusion: { in: [true, false] }
  validates :token_version, presence: true, numericality: { greater_than_or_equal_to: 0 }

  enum role: { employee: 'employee', admin: 'admin' }

  def self.search_by_name(name)
    UserQuery.new.search_by_name(name).to_relation
  end

  def self.search_by_email(email)
    UserQuery.new.search_by_email(email).to_relation
  end

  def self.search_by_role(role)
    UserQuery.new.search_by_role(role).to_relation
  end

  def self.search_by_active(active)
    UserQuery.new.search_by_active(active).to_relation
  end

  def self.search(query)
    UserQuery.new.search_global(query).to_relation
  end

  def self.order_by_name(direction = 'asc')
    Users::SortStrategy.new(UserQuery.new, { sort_by: 'name', order: direction }).execute.to_relation
  end

  def self.order_by_email(direction = 'asc')
    Users::SortStrategy.new(UserQuery.new, { sort_by: 'email', order: direction }).execute.to_relation
  end

  def self.order_by_role(direction = 'asc')
    Users::SortStrategy.new(UserQuery.new, { sort_by: 'role', order: direction }).execute.to_relation
  end

  def self.order_by_created_at(direction = 'desc')
    Users::SortStrategy.new(UserQuery.new, { sort_by: 'created_at', order: direction }).execute.to_relation
  end

  def active?
    active == true
  end

  def admin?
    role == 'admin'
  end

  def employee?
    role == 'employee'
  end

  def full_name
    name
  end

  def generate_jwt_token
    payload = {
      user_id: id,
      email: email,
      role: role,
      token_version: token_version,
      exp: 1.hour.from_now.to_i
    }
    JWT.encode(payload, Rails.application.credentials.secret_key_base)
  end

  def self.decode_jwt_token(token)
    decoded_token = JWT.decode(token, Rails.application.credentials.secret_key_base)[0]
    user = User.find(decoded_token['user_id'])
    
    if user && user.token_version == decoded_token['token_version']
      user
    else
      nil
    end
  rescue JWT::DecodeError, ActiveRecord::RecordNotFound
    nil
  end

  def invalidate_all_tokens!
    increment!(:token_version)
  end

  def refresh_token!
    invalidate_all_tokens!
    generate_jwt_token
  end

  def active_for_authentication?
    super && active?
  end

  def inactive_message
    active? ? super : :account_inactive
  end

  def as_json_response
    {
      id: id,
      name: name,
      email: email,
      role: role,
      active: active,
      created_at: created_at,
      updated_at: updated_at
    }
  end
end
