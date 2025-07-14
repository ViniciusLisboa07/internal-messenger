class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :trackable

  validates :name, presence: true, length: { minimum: 2, maximum: 50 }
  validates :email, presence: true, uniqueness: { case_sensitive: false }
  validates :role, inclusion: { in: %w[admin employee] }
  validates :active, inclusion: { in: [true, false] }

  enum role: { employee: 'employee', admin: 'admin' }

  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }
  scope :admins, -> { where(role: 'admin') }
  scope :employees, -> { where(role: 'employee') }

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
      name: name,
      role: role,
      exp: 24.hours.from_now.to_i
    }
    JWT.encode(payload, Rails.application.credentials.secret_key_base)
  end

  def self.decode_jwt_token(token)
    decoded_token = JWT.decode(token, Rails.application.credentials.secret_key_base)[0]
    User.find(decoded_token['user_id'])
  rescue JWT::DecodeError, ActiveRecord::RecordNotFound
    nil
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
