# app/models/note.rb
class Note < ApplicationRecord
  belongs_to :user, inverse_of: :notes
  has_and_belongs_to_many :categories
  
  validates :title, presence: true, length: { in: 1..50 }
  validates :body,  presence: true, length: { maximum: 1000 }
  validate  :title_does_not_contain_taboo_words

  scope :recent, -> { order(created_at: :desc).limit(20) }
  scope :by_user, -> (user_id) { where(user_id: user_id) }
  scope :publicly_accessible, -> { where(public: true) }

  TABOO_BASE = %w[
    fuck shit bitch bastard crap damn piss dick pussy asshole slut whore porn
    balls prick douche goddamn motherfucker bullshit jackass
  ].freeze

  TABOO_VARIANTS = %w[
    fvck f*ck f_ck f.u.c.k
    sh1t s#it s**t
    b!tch bi7ch b1tch
    a$$ a55 a$$hole a55hole
    d1ck d!ck
    p*ssy p@ssy
    wh0re w#ore
    slvt s!ut
    c0ck c*ck
  ].freeze

  LEET = { "@" => "a", "$" => "s", "1" => "i", "!" => "i", "3" => "e", "0" => "o", "5" => "s" }.freeze

  TABOO_REGEX = begin
    blocklist = (TABOO_BASE + TABOO_VARIANTS).map { |w| Regexp.escape(w) }.join("|")
    /\b(?:#{blocklist})\b/i.freeze
  end

  private

  def title_does_not_contain_taboo_words
    return if title.blank?
    norm = normalize_for_filter(title)
    errors.add(:title, "contains inappropriate language") if TABOO_REGEX.match?(norm)
  end

  def normalize_for_filter(text)
    text.to_s.downcase.tr(LEET.keys.join, LEET.values.join)
  end
end
