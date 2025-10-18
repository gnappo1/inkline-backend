class FriendshipSerializer < ApplicationSerializer
  set_type :friendships

  attributes :status, :sender_id, :receiver_id, :effective_timestamp

  attribute :effective_timestamp do |f|
    (f.accepted? ? f.updated_at : f.created_at)&.utc&.iso8601
  end

  def self.me_id(params)
    return nil unless params
    params[:current_user_id] || params[:current_user]&.id
  end

  attribute :other_user_id do |fr, params|
    me = me_id(params)
    if me
      fr.sender_id == me ? fr.receiver_id : fr.sender_id
    else
      fr.receiver_id
    end
  end

  attribute :other_user_name do |fr, params|
    me = me_id(params)
    other =
      if me && fr.sender_id == me
        fr.receiver
      elsif me && fr.receiver_id == me
        fr.sender
      else
        fr.receiver
      end
    "#{other.id} - #{other.first_name} #{other.last_name}"
  end
end
