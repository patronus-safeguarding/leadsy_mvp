class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # Associations
  has_many :access_templates, dependent: :destroy
  has_many :access_requests, through: :access_templates
  has_many :audit_events, dependent: :destroy

  # Validations
  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :agency_name, presence: true, if: :is_owner?

  # Scopes
  scope :owners, -> { where(is_owner: true) }

  # Methods
  def full_name
    "#{first_name} #{last_name}"
  end

  def owner?
    is_owner?
  end
end
