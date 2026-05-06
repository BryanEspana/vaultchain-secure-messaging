class Group < ApplicationRecord
  belongs_to :creator, class_name: "User", foreign_key: :creator_id
  has_many :group_members, dependent: :destroy
  has_many :members, through: :group_members, source: :user
  has_many :messages, foreign_key: :group_id, dependent: :destroy

  validates :name, presence: true
end
