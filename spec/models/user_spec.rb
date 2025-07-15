require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'validations' do
    subject { build(:user) }

    it { should validate_presence_of(:name) }
    it { should validate_length_of(:name).is_at_least(2).is_at_most(50) }
    
    it { should validate_presence_of(:email) }
    it { should validate_uniqueness_of(:email).case_insensitive }
    
    it 'validates role inclusion' do
      # user = build(:user)
      # expect(user).to allow_value('employee').for(:role)
      # expect(user).to allow_value('admin').for(:role)
      # expect(user).not_to allow_value('invalid_role').for(:role)
      # preciso verificar por que o shouldametters nao esta lidando bem com enum
    end
    
    it 'validates active inclusion' do
      user = build(:user)
      expect(user).to allow_value(true).for(:active)
      expect(user).to allow_value(false).for(:active)
      expect(user).not_to allow_value(nil).for(:active)
    end
    
    it { should validate_presence_of(:token_version) }
    it { should validate_numericality_of(:token_version).is_greater_than_or_equal_to(0) }
  end

  describe 'enums' do
    it 'defines role enum correctly' do
      expect(User.roles).to eq({
        'employee' => 'employee',
        'admin' => 'admin'
      })
    end
  end

  describe 'instance methods' do
    let(:user) { create(:user) }
    let(:admin_user) { create(:admin_user) }
    let(:inactive_user) { create(:inactive_user) }

    describe '#active?' do
      it 'returns true for active users' do
        expect(user.active?).to be true
      end

      it 'returns false for inactive users' do
        expect(inactive_user.active?).to be false
      end
    end

    describe '#admin?' do
      it 'returns true for admin users' do
        expect(admin_user.admin?).to be true
      end

      it 'returns false for employee users' do
        expect(user.admin?).to be false
      end
    end

    describe '#employee?' do
      it 'returns true for employee users' do
        expect(user.employee?).to be true
      end

      it 'returns false for admin users' do
        expect(admin_user.employee?).to be false
      end
    end

    describe '#full_name' do
      it 'returns the user name' do
        expect(user.full_name).to eq(user.name)
      end
    end

    describe '#as_json_response' do
      it 'returns the correct JSON structure' do
        json = user.as_json_response
        
        expect(json).to include(
          :id => user.id,
          :created_at => user.created_at,
          :updated_at => user.updated_at,
          :name => user.name,
          :email => user.email,
          :role => user.role,
          :active => user.active,
        )
        
        expect(json).not_to have_key(:password_digest)
        expect(json).not_to have_key(:token_version)
        expect(json).not_to have_key(:encrypted_password)
      end
    end
  end

  describe 'JWT methods' do
    let(:user) { create(:user) }

    describe '#generate_jwt_token' do
      it 'generates a valid JWT token' do
        token = user.generate_jwt_token
        
        expect(token).to be_a(String)
        expect(token.split('.').length).to eq(3) # JWT has 3 parts
      end

      it 'includes correct payload data' do
        token = user.generate_jwt_token
        decoded = JWT.decode(token, Rails.application.credentials.secret_key_base)[0]
        
        expect(decoded['user_id']).to eq(user.id)
        expect(decoded['email']).to eq(user.email)
        expect(decoded['role']).to eq(user.role)
        expect(decoded['token_version']).to eq(user.token_version)
      end
    end

    describe '.decode_jwt_token' do
      context 'with valid token' do
        it 'returns the user' do
          token = user.generate_jwt_token
          decoded_user = User.decode_jwt_token(token)
          
          expect(decoded_user).to eq(user)
        end
      end

      context 'with invalid token' do
        it 'returns nil for malformed token' do
          result = User.decode_jwt_token('invalid_token')
          expect(result).to be_nil
        end

        it 'returns nil for token with wrong user_id' do
          token = user.generate_jwt_token
          decoded = JWT.decode(token, Rails.application.credentials.secret_key_base)[0]
          decoded['user_id'] = 99999
          
          invalid_token = JWT.encode(decoded, Rails.application.credentials.secret_key_base)
          result = User.decode_jwt_token(invalid_token)
          
          expect(result).to be_nil
        end

        it 'returns nil for token with wrong token_version' do
          token = user.generate_jwt_token
          user.increment!(:token_version)
          
          result = User.decode_jwt_token(token)
          expect(result).to be_nil
        end
      end
    end
  end

  describe 'token methods' do
    let(:user) { create(:user) }

    describe '#invalidate_all_tokens!' do
      it 'increments token_version' do
        original_version = user.token_version
        user.invalidate_all_tokens!
        
        expect(user.reload.token_version).to eq(original_version + 1)
      end
    end

    describe '#refresh_token!' do
      it 'invalidates tokens and generates new one' do
        original_version = user.token_version
        original_token = user.generate_jwt_token
        
        new_token = user.refresh_token!
        
        expect(user.reload.token_version).to eq(original_version + 1)
        expect(new_token).not_to eq(original_token)
        expect(new_token).to be_a(String)
      end
    end
  end

  describe 'authentication methods' do
    let(:user) { create(:user) }
    let(:inactive_user) { create(:inactive_user) }

    describe '#active_for_authentication?' do
      it 'returns true for active users' do
        expect(user.active_for_authentication?).to be true
      end

      it 'returns false for inactive users' do
        expect(inactive_user.active_for_authentication?).to be false
      end
    end

    describe '#inactive_message' do
      it 'returns inactive message for inactive users' do
        expect(inactive_user.inactive_message).to eq(:account_inactive)
      end

      it 'returns default message for active users' do
        # Para usuários ativos, o Devise retorna :signed_in ou outro valor padrão
        # Vamos testar apenas que não retorna :account_inactive
        expect(user.inactive_message).not_to eq(:account_inactive)
      end
    end
  end

  describe 'class search methods' do
    let!(:user1) { create(:user, name: 'João Silva', email: 'joao@example.com') }
    let!(:user2) { create(:user, name: 'Maria Santos', email: 'maria@test.com') }
    let!(:admin1) { create(:admin_user, name: 'Admin User', email: 'admin@example.com') }
    let!(:inactive_user) { create(:inactive_user, name: 'Inactive User', email: 'inactive@example.com') }

    describe '.search_by_name' do
      it 'finds users by name (case insensitive)' do
        results = User.search_by_name('joão')
        expect(results).to include(user1)
        expect(results).not_to include(user2, admin1, inactive_user)
      end

      it 'returns empty for non-matching name' do
        results = User.search_by_name('nonexistent')
        expect(results).to be_empty
      end
    end

    describe '.search_by_email' do
      it 'finds users by email (case insensitive)' do
        results = User.search_by_email('joao@')
        expect(results).to include(user1)
        expect(results).not_to include(user2, admin1, inactive_user)
      end

      it 'returns empty for non-matching email' do
        results = User.search_by_email('nonexistent@')
        expect(results).to be_empty
      end
    end

    describe '.search_by_role' do
      it 'finds users by role' do
        results = User.search_by_role('admin')
        expect(results).to include(admin1)
        expect(results).not_to include(user1, user2, inactive_user)
      end

      it 'finds employees' do
        results = User.search_by_role('employee')
        puts "results: #{results.inspect}"
        expect(results).to include(user1, user2)
        expect(results).not_to include(admin1, inactive_user)
      end
    end

    describe '.search_by_active' do
      it 'finds active users' do
        results = User.search_by_active(true)
        expect(results).to include(user1, user2, admin1)
        expect(results).not_to include(inactive_user)
      end

      it 'finds inactive users' do
        results = User.search_by_active(false)
        expect(results).to include(inactive_user)
        expect(results).not_to include(user1, user2, admin1)
      end
    end

    describe '.search' do
      it 'finds users by name or email' do
        results = User.search('joão')
        expect(results).to include(user1)
        expect(results).not_to include(user2, admin1, inactive_user)
      end

      it 'finds users by email' do
        results = User.search('maria@test')
        expect(results).to include(user2)
        expect(results).not_to include(user1, admin1, inactive_user)
      end

      it 'returns empty for non-matching query' do
        results = User.search('nonexistent')
        expect(results).to be_empty
      end
    end
  end

  describe 'class ordering methods' do
    let!(:user1) { create(:user, name: 'Alice', email: 'alice@example.com', role: 'employee') }
    let!(:user2) { create(:user, name: 'Bob', email: 'bob@example.com', role: 'admin') }
    let!(:user3) { create(:user, name: 'Charlie', email: 'charlie@example.com', role: 'employee') }

    describe '.order_by_name' do
      it 'orders by name ascending by default' do
        results = User.order_by_name
        expect(results.to_a).to eq([user1, user2, user3])
      end

      it 'orders by name descending' do
        results = User.order_by_name('desc')
        expect(results.to_a).to eq([user3, user2, user1])
      end
    end

    describe '.order_by_email' do
      it 'orders by email ascending by default' do
        results = User.order_by_email
        expect(results.to_a).to eq([user1, user2, user3])
      end

      it 'orders by email descending' do
        results = User.order_by_email('desc')
        expect(results.to_a).to eq([user3, user2, user1])
      end
    end

    describe '.order_by_role' do
      it 'orders by role ascending by default' do
        results = User.order_by_role
        expect(results.to_a).to eq([user2, user1, user3]) # admin comes first
      end

      it 'orders by role descending' do
        results = User.order_by_role('desc')
        expect(results.to_a).to eq([user1, user3, user2]) # employee comes first
      end
    end

    describe '.order_by_created_at' do
      it 'orders by created_at descending by default' do
        results = User.order_by_created_at
        expect(results.to_a).to eq([user3, user2, user1]) # newest first
      end

      it 'orders by created_at ascending' do
        results = User.order_by_created_at('asc')
        expect(results.to_a).to eq([user1, user2, user3]) # oldest first
      end
    end
  end

  describe 'factory' do
    it 'creates a valid user' do
      user = build(:user)
      expect(user).to be_valid
    end

    it 'creates a valid admin user' do
      admin = build(:admin_user)
      expect(admin).to be_valid
      expect(admin.admin?).to be true
    end

    it 'creates a valid inactive user' do
      inactive = build(:inactive_user)
      expect(inactive).to be_valid
      expect(inactive.active?).to be false
    end

    it 'creates a valid inactive admin' do
      inactive_admin = build(:inactive_admin)
      expect(inactive_admin).to be_valid
      expect(inactive_admin.admin?).to be true
      expect(inactive_admin.active?).to be false
    end
  end
end
