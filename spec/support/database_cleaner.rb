RSpec.configure do |config|
  config.before(:suite) do
    DatabaseCleaner.clean_with(:truncation) if defined?(DatabaseCleaner)
  end

  config.before(:each) do
    DatabaseCleaner.strategy = :transaction if defined?(DatabaseCleaner)
  end

  config.before(:each) do
    DatabaseCleaner.start if defined?(DatabaseCleaner)
  end

  config.after(:each) do
    DatabaseCleaner.clean if defined?(DatabaseCleaner)
  end
end 