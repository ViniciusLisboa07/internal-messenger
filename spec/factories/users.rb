FactoryBot.define do
  factory :user do
    sequence(:name) { |n| "User #{n}" }
    sequence(:email) { |n| "user#{n}@example.com" }
    password { "password123" }
    password_confirmation { "password123" }
    role { "employee" }
    active { true }
    token_version { 0 }

    trait :admin do
      role { "admin" }
    end

    trait :inactive do
      active { false }
    end

    trait :with_tokens do
      token_version { 5 }
    end

    trait :with_name do
      sequence(:name) { |n| "Test User #{n}" }
    end

    trait :with_email do
      sequence(:email) { |n| "test#{n}@company.com" }
    end

    trait :recent do
      created_at { Time.current }
      updated_at { Time.current }
    end

    trait :old do
      created_at { 1.month.ago }
      updated_at { 1.week.ago }
    end

    factory :admin_user, traits: [:admin]

    factory :inactive_user, traits: [:inactive]

    factory :inactive_admin, traits: [:admin, :inactive]
  end
end
