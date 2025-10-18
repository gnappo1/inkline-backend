# frozen_string_literal: true
class ApplicationSerializer
  include JSONAPI::Serializer
  set_key_transform :underscore 
  set_id :id
end