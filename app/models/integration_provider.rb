class IntegrationProvider < ApplicationRecord
  # Enums
  enum :provider_type, {
    meta: 'meta',
    google: 'google',
    tiktok: 'tiktok',
    linkedin: 'linkedin'
  }

  # Associations
  has_many :access_grants, dependent: :destroy

  # Validations
  validates :name, presence: true
  validates :provider_type, presence: true
  validates :client_id, presence: true
  validates :oauth_authorize_url, presence: true
  validates :oauth_token_url, presence: true
  validates :scopes, presence: true

  # Scopes
  scope :by_type, ->(type) { where(provider_type: type) }

  # Methods
  def display_name
    "#{name} (#{provider_type.titleize})"
  end

  def client_secret
    client_secret_encrypted
  end

  def client_secret=(value)
    self.client_secret_encrypted = value
  end

  def available_scopes
    # Parse the scopes JSON and return as array
    return [] if scopes.blank?
    
    if scopes.is_a?(String)
      JSON.parse(scopes) rescue []
    elsif scopes.is_a?(Array)
      scopes
    else
      []
    end
  end
end
