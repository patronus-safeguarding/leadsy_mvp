class AccessGrant < ApplicationRecord
  # Encrypted attributes
  encrypts :access_token_encrypted, :refresh_token_encrypted

  # Associations
  belongs_to :access_request
  belongs_to :integration_provider

  # Enums
  enum :status, {
    active: 'active',
    expired: 'expired',
    revoked: 'revoked',
    error: 'error'
  }

  # Validations
  validates :provider_account_id, presence: true
  validates :access_request_id, uniqueness: { scope: :integration_provider_id }

  # Scopes
  scope :active, -> { where(status: 'active') }
  scope :by_provider, ->(provider) { where(integration_provider: provider) }

  # Methods
  def access_token
    access_token_encrypted
  end

  def access_token=(value)
    self.access_token_encrypted = value
  end

  def refresh_token
    refresh_token_encrypted
  end

  def refresh_token=(value)
    self.refresh_token_encrypted = value
  end

  def token_expired?
    token_expires_at && token_expires_at < Time.current
  end

  def needs_refresh?
    token_expires_at && token_expires_at < 1.hour.from_now
  end

  def client
    access_request.client
  end

  def template
    access_request.access_template
  end
end
