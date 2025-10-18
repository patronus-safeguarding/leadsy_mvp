class AccessGrant < ApplicationRecord
  # Encrypted attributes using Rails built-in encryption
  encrypts :access_token, :refresh_token

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
