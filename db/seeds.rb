puts "Seeding common data..."
# common seeds here

env_seed = Rails.root.join("db", "seeds", "#{Rails.env}.rb")
load env_seed if File.exist?(env_seed)