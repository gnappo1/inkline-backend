# frozen_string_literal: true
class ApplicationSerializer
  include JSONAPI::Serializer
  set_key_transform :underscore   # 👈 snake_case keys across the board
  set_id :id
end