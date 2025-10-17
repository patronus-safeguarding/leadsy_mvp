class Client < ApplicationRecord
  # Associations
  has_many :access_requests, dependent: :destroy
  has_many :access_grants, through: :access_requests

  # Validations
  validates :name, presence: true
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :company, presence: true

  # Scopes
  scope :by_company, ->(company) { where(company: company) }

  # Methods
  def display_name
    "#{name} (#{company})"
  end
end
