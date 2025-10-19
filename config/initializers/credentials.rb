# Configure Rails to use environment variables instead of credentials file
if Rails.env.production?
  # Ensure Rails doesn't try to read credentials file
  Rails.application.configure do
    # Use environment variables for secret key base
    config.secret_key_base = ENV['SECRET_KEY_BASE']
  end
end
