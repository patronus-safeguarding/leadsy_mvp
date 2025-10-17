class AccessTemplate < ApplicationRecord
  # Associations
  belongs_to :user
  has_many :access_requests, dependent: :destroy

  # Validations
  validates :name, presence: true
  validates :provider_scopes, presence: true

  # Scopes
  scope :by_user, ->(user) { where(user: user) }

  # Methods
  def provider_scopes_for(provider_type)
    provider_scopes[provider_type.to_s] || []
  end

  def available_providers
    provider_scopes.keys
  end

  def has_scope?(provider_type, scope)
    provider_scopes_for(provider_type).include?(scope.to_s)
  end
end
