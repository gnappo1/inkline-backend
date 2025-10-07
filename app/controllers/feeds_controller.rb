class FeedsController < ApplicationController
  DEFAULT_LIMIT = 20

  def public_notes
    limit = params.fetch(:limit, DEFAULT_LIMIT).to_i.clamp(1, 100)

    notes = Note.publicly_accessible
                .feed_order
                .includes(:user, :categories)

    if params[:before].present?
      ts, id = decode_cursor(params[:before])
      notes  = notes.before_cursor(ts, id)
    elsif params[:after].present?
      ts, id = decode_cursor(params[:after])
      notes  = notes.after_cursor(ts, id).reorder(created_at: :asc, id: :asc)
    end

    notes = notes.limit(limit)
    notes = notes.reorder(created_at: :desc, id: :desc) if params[:after].present?

    render_jsonapi(
      notes,
      serializer: NoteSerializer,
      include: [], # we don't need side-loaded resources with flattened attrs
      meta: {
        next_cursor: next_cursor_for(notes),
        prev_cursor: prev_cursor_for(notes)
      },
      status: 200
    )
  end

  private

  def encode_cursor(note)
    Base64.urlsafe_encode64("#{note.created_at.utc.iso8601(6)},#{note.id}")
  end

  def decode_cursor(str)
    raw = Base64.urlsafe_decode64(str)
    ts_s, id_s = raw.split(",", 2)
    [Time.iso8601(ts_s), Integer(id_s)]
  end

  def next_cursor_for(relation) = relation.last && encode_cursor(relation.last)
  def prev_cursor_for(relation) = relation.first && encode_cursor(relation.first)
end
