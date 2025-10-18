class NoteSerializer
  include JSONAPI::Serializer
  set_type :notes

  attributes :title, :body, :public, :created_at, :updated_at

  attribute :author do |note|
    u = note.user
    u ? { id: u.id, first_name: u.first_name, last_name: u.last_name } : nil
  end

  attribute :categories do |note|
    note.categories.map { |c| { id: c.id, name: c.name } }
  end
end
