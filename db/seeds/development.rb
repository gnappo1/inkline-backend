require "faker"

abort("Refusing to seed in production") if Rails.env.production?

puts "Resetting data..."
# Fast truncate style reset
Note.delete_all
User.delete_all
puts "data reset complete! ✅"

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
puts "user seed complete! ✅"

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
puts "note seed complete! ✅"

puts "staggering timestamps for notes due to mass insertion"
Note.publicly_accessible.order(id: :desc).each_with_index do |n, i|
  ts = Time.current - i.seconds
  n.update_columns(created_at: ts, updated_at: ts)
end
puts "note timestamp staggering complete! ✅"

puts "creating categories..."
categories_data = %w[
  Productivity Ideas Journal Tech Design Personal Travel Books Finance Wellness
  Programming Writing Learning Inspiration Research Music Movies Food Fitness
]

# idempotent upserts for categories
categories = categories_data.map do |name|
  Category.where(name: name).first_or_create!
end
puts "category seed complete! ✅"

puts "Assigning categories to notes…"
# Attach 1–4 random categories to each public note
Note.find_each do |n|
  # pick 1..4 unique categories
  picks = categories.sample(rand(1..4))
  # replace existing (idempotent)
  n.categories = picks
  n.save!  # will validate Note again, which is fine here
end
puts "Categories seeded and attached."

puts "Done."