class Message < ApplicationRecord
  belongs_to :sender, class_name: 'User', optional: true
  belongs_to :recipient, class_name: 'User', optional: true
  
  # group_id points to a Group model that will be created later.
end
