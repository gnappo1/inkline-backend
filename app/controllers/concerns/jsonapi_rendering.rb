# frozen_string_literal: true
module JsonapiRendering
  extend ActiveSupport::Concern

  def render_jsonapi(record_or_relation, serializer:, status: 200, include: [], fields: nil, meta: nil)
    opts = {}
    opts[:include] = include if include.present?
    opts[:fields]  = fields  if fields.present?
    opts[:meta]    = meta    if meta.present?
    # pass current_user + include list into params for conditional attributes
    opts[:params]  = { current_user: @current_user, include: Array(include).map(&:to_s) }

    hash =
      if record_or_relation.respond_to?(:to_ary)
        serializer.new(record_or_relation, **opts).serializable_hash
      else
        serializer.new(record_or_relation, **opts).serializable_hash
      end

    render json: hash, status: status
  end
end
