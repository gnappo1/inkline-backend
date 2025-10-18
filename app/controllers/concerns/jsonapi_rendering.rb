# frozen_string_literal: true
module JsonapiRendering
  extend ActiveSupport::Concern

  def render_jsonapi(record_or_relation, serializer:, status: 200, include: [], fields: nil, meta: nil, params: nil)
    opts = {}
    opts[:include] = include if include.present?
    opts[:fields]  = fields  if fields.present?
    opts[:meta]    = meta    if meta.present?

    p = params.is_a?(Hash) ? params.dup : {}
    p[:current_user]     ||= @current_user
    p[:current_user_id]  ||= @current_user&.id
    opts[:params] = p

    render json: serializer.new(record_or_relation, **opts).serializable_hash, status: status
  end
end
