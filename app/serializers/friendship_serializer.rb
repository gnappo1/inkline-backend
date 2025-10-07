class FriendshipSerializer < ApplicationSerializer
  set_type :friendships

  attributes :status, :created_at, :updated_at, :sender_id, :receiver_id

  # Convenience attribute: effective timestamp (created for pending, updated for accepted)
  attribute :effective_timestamp do |f|
    f.accepted? ? f.updated_at&.utc&.iso8601 : f.created_at&.utc&.iso8601
  end

  # If you want a single “other user” convenience string (optional):
  attribute :other_user_name do |f, params|
    cu = params&.dig(:current_user)
    other =
      if cu&.id == f.sender_id
        f.receiver
      elsif cu&.id == f.receiver_id
        f.sender
      end
    other ? "#{other.first_name} #{other.last_name}" : nil
  end

  # True JSON:API relationships (don’t include both unless asked)
  belongs_to :sender,   record_type: :users
  belongs_to :receiver, record_type: :users
end
