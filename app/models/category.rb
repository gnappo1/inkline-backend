class Category < ApplicationRecord
  has_and_belongs_to_many :notes

  before_validation :normalize_name

  validates :name,
            presence: true,
            length: { in: 2..30 },
            uniqueness: { case_sensitive: false }
  validate  :name_does_not_contain_taboo_words

  TABOO_BASE = %w[fuck shit bitch bastard crap damn piss dick pussy asshole slut whore porn
                  balls prick douche goddamn motherfucker bullshit jackass].freeze
  TABOO_VARIANTS = %w[fvck f*ck f_ck f.u.c.k sh1t s#it s**t b!tch bi7ch b1tch a$$ a55 a$$hole a55hole
                      d1ck d!ck p*ssy p@ssy wh0re w#ore slvt s!ut c0ck c*ck].freeze
  LEET = { "@"=>"a", "$"=>"s", "1"=>"i", "!"=>"i", "3"=>"e", "0"=>"o", "5"=>"s" }.freeze

  TABOO_REGEX = begin
    blocklist = (TABOO_BASE + TABOO_VARIANTS).map { |w| Regexp.escape(w) }.join("|")
    /\b(?:#{blocklist})\b/i
  end

  private

  def name_does_not_contain_taboo_words
    return if name.blank?
    norm = name.to_s.downcase.tr(LEET.keys.join, LEET.values.join)
    errors.add(:name, "contains inappropriate language") if TABOO_REGEX.match?(norm)
  end

  def normalize_name
    self.name = name.to_s.squish.downcase
  end
end
