# Configure Active Record encryption for production
if Rails.env.production?
  encryption_key = ENV['ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY']
  
  if encryption_key.present?
    Rails.application.configure do
      config.active_record.encryption.primary_key = encryption_key
      config.active_record.encryption.deterministic_key = encryption_key
      config.active_record.encryption.key_derivation_salt = encryption_key
    end
    
    Rails.logger.info "Active Record encryption configured with environment variable"
  else
    Rails.logger.warn "ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY not set - encryption may not work properly"
  end
end
