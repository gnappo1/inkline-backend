class Friendship < ApplicationRecord
  belongs_to :sender, class_name: "User"
  belongs_to :receiver, class_name: "User"

  enum :status,
      {pending: "pending", accepted: "accepted", rejected: "rejected", canceled: "canceled", blocked: "blocked"},
      validate: true
  
  validates :sender_id, :receiver_id, presence: true
  validate :not_self

  scope :between, -> (a_id, b_id) do
    where(
      "(sender_id = :a AND receiver_id = :b) OR (sender_id = :b AND receiver_id = :a)",
      a: a_id, b: b_id
    )
  end

  scope :involving, -> (user_id) { where("sender_id = :id OR receiver_id = :id", id: user_id) }
  scope :accepted_only, -> { where(status: "accepted") }
  scope :pending_only, -> { where(status: "pending") }

  private
  def not_self
    errors.add(:receiver_id, "Cannot be the same as sender_id") if sender_id.present? && sender_id == receiver_id
  end
end
