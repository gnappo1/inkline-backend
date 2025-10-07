class Category < ApplicationRecord
  has_and_belongs_to_many :notes
  before_validation { self.name = name.to_s.squish.downcase }
  validates :name, presence: true, length: { in: 2..30 }, uniqueness: { case_sensitive: false }, profanity: true

end
