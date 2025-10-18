class User < ApplicationRecord
  include Normalizers::Email
  has_many :notes, dependent: :destroy, inverse_of: :user
  has_many :sent_friendships, 
          class_name: "Friendship",
          foreign_key: :sender_id,
          dependent: :destroy,
          inverse_of: :sender

  has_many :received_friendships, 
          class_name: "Friendship",
          foreign_key: :receiver_id,
          dependent: :destroy,
          inverse_of: :receiver
  
  has_many :accepted_sent_friendships,
        -> { accepted_only },
        class_name: "Friendship",
        foreign_key: :sender_id

  has_many :pending_sent_friendships,
        -> { pending_only },
        class_name: "Friendship",
        foreign_key: :sender_id
  
  has_many :accepted_received_friendships,
        -> { accepted_only },
        class_name: "Friendship",
        foreign_key: :receiver_id

  has_many :pending_received_friendships,
        -> { pending_only },
        class_name: "Friendship",
        foreign_key: :receiver_id
  
  has_many :friends_as_sender, through: :accepted_sent_friendships, source: :receiver
  has_many :friends_as_receiver, through: :accepted_received_friendships, source: :sender

  has_secure_password

  before_validation :normalize_name_and_email

  validates :first_name, presence: true, length: { in: 1..50 }
  validates :last_name,  presence: true, length: { in: 1..50 }
  validates :email,
            presence: true, 
            uniqueness: { case_sensitive: false },
            length: { maximum: 320 },
            format: { with: URI::MailTo::EMAIL_REGEXP, message: "is not a valid email" }
  validates :password,
            length: { in: 8..25 },
            allow_nil: true

  enum :role,
       { client: "client", admin: "admin", superadmin: "superadmin" },
       default: "client",
       validate: true

  scope :recent, -> { order(created_at: :desc, id: :desc)}
  scope :by_email, -> (email) do 
    norm = normalize_email_for_query(email)
    norm.present? ? where("LOWER(email) = ?", norm) : none
  end

  def friends
    User.where(id: friend_ids)
  end

  def friend_ids
    Friendship.accepted_only
      .involving(id)
      .pluck(Arel.sql("CASE WHEN sender_id = #{id} THEN receiver_id ELSE sender_id END"))
  end

  def send_friend_request(to_user_id)
    Friendship.create!(sender_id: id, receiver_id: to_user_id, status: :pending)
  end

  def respond_to_friendship!(other_user_id, action)
    fr = Friendship.between(id, other_user_id).first or
          raise ActiveRecord::RecordNotFound, "No friendship request"

    case action.to_sym
    when :accept
      raise "Only receiver can accept" unless fr.receiver_id == id
      raise "Not pending" unless fr.pending?
      fr.update!(status: :accepted)

    when :reject
      raise "Only receiver can decline" unless fr.receiver_id == id
      raise "Not pending" unless fr.pending?
      fr.destroy!

    when :cancel
      raise "Only sender can cancel" unless fr.sender_id == id
      raise "Not pending" unless fr.pending?
      fr.destroy!

    when :unfriend
      raise "Only accepted friendships can be removed" unless fr.accepted?
      raise "Not a participant" unless [fr.sender_id, fr.receiver_id].include?(id)
      fr.destroy!

    when :block
      raise "Only accepted friends can be blocked" unless fr.accepted?
      raise "Not a participant" unless [fr.sender_id, fr.receiver_id].include?(id)
      fr.update!(status: "blocked", sender_id: id, receiver_id: other_user_id)

    else
      raise ArgumentError, "Unknown action: #{action}"
    end

    fr
  end

  private
  def normalize_name_and_email
    self.email = self.class.normalize_email_for_query(email)
    self.first_name = first_name.to_s.squish
    self.last_name = last_name.to_s.squish
  end
end
