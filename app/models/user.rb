class User < ApplicationRecord
  has_secure_password

  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :display_name, presence: true
end
