# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

require "faker"

abort("Refusing to seed in production") if Rails.env.production?

puts "Resetting data..."
# Fast truncate style reset
Note.delete_all
User.delete_all


puts "Creating users..."
users = []
10.times do
  users << User.create!(
    first_name: Faker::Name.first_name,
    last_name:  Faker::Name.last_name,
    email:      Faker::Internet.unique.email(domain: "gmail.com"),
    password:   "password"
  )
end

puts "Creating notes..."
users.each do |u|
  rand(0..9).times do
    u.notes.create!(
      title: Faker::Lorem.words(number: 4, supplemental: true).join(" "),
      body:  Faker::Lorem.paragraph_by_chars(number: 300),
      public: true
    )
  end
end

puts "Done."