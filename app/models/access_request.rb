class AccessRequest < ApplicationRecord
  # Associations
  belongs_to :access_template
  belongs_to :client
  has_many :access_grants, dependent: :destroy

  # Enums
  enum :status, {
    pending: 'pending',
    approved: 'approved',
    expired: 'expired',
    cancelled: 'cancelled'
  }

  # Validations
  validates :token, presence: true, uniqueness: true
  validates :expires_at, presence: true

  # Callbacks
  before_validation :generate_token, on: :create
  before_validation :set_expires_at, on: :create

  # Scopes
  scope :active, -> { where(status: ['pending', 'approved']) }
  scope :expired, -> { where('expires_at < ?', Time.current) }
  scope :by_token, ->(token) { where(token: token) }

  # Methods
  def expired?
    expires_at < Time.current
  end

  def can_be_accessed?
    active? && !expired?
  end

  def grant_for_provider(provider)
    access_grants.find_by(integration_provider: provider)
  end

  def providers_granted
    access_grants.includes(:integration_provider).map(&:integration_provider)
  end

  private

  def generate_token
    self.token ||= SecureRandom.urlsafe_base64(32)
  end

  def set_expires_at
    self.expires_at ||= 7.days.from_now
  end
end
