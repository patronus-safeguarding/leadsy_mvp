# Rails Active Record Encryption Configuration
# For development only - use proper secrets management in production

if Rails.env.development?
  # Generate development encryption keys
  Rails.application.configure do
    config.active_record.encryption.primary_key = "development_primary_key_32_chars_long!"
    config.active_record.encryption.deterministic_key = "development_deterministic_key_32_chars!"
    config.active_record.encryption.key_derivation_salt = "development_salt_32_chars_long!"
  end
end
