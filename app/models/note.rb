# app/models/note.rb
class Note < ApplicationRecord
  belongs_to :user, inverse_of: :notes
  has_and_belongs_to_many :categories

  validates :title, presence: true, length: { in: 1..50 }, profanity: true
  validates :body,  presence: true, length: { maximum: 1000 }, profanity: true

  scope :recent, -> { order(created_at: :desc).limit(20) }
  scope :by_user, -> (user_id) { where(user_id: user_id) }
  scope :publicly_accessible, -> { where(public: true) }
  scope :feed_order, -> { order(created_at: :desc, id: :desc) }

  scope :before_cursor, ->(ts, id) {
    where("created_at < ? OR (created_at = ? AND id < ?)", ts, ts, id)
  }
  
  scope :after_cursor, ->(ts, id) {
    where("created_at > ? OR (created_at = ? AND id > ?)", ts, ts, id)
  }

  scope :with_owner, -> { includes(:user) }

end
