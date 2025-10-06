class FeedsController < ApplicationController
  DEFAULT_LIMIT = 20

  def public_notes
    limit = [params.fetch(:limit, DEFAULT_LIMIT).to_i, 100].min

    notes = Note.publicly_visible.feed_order
    if params[:before].present?
      ts, id = decode_cursor(params[:before])
      notes = notes.before_cursor(ts, id)
    elsif params[:after].present?
      ts, id = decode_cursor(params[:after])
      notes = notes.after_cursor(ts, id).reorder(created_at: :asc, id: :asc) # forward page
    end

    notes = notes.limit(limit)
    notes = notes.reorder(created_at: :desc, id: :desc) if params[:after].present?

    render json: {
      data: notes.as_json(only: [:id, :title, :body, :user_id, :public, :created_at, :updated_at]),
      next_cursor: next_cursor_for(notes),
      prev_cursor: prev_cursor_for(notes)
    }, status: 200
  end

  private

  def encode_cursor(note)
    Base64.urlsafe_encode64("#{note.created_at.utc.iso8601},#{note.id}")
  end

  def decode_cursor(str)
    raw = Base64.urlsafe_decode64(str)
    ts_s, id_s = raw.split(",", 2)
    [Time.iso8601(ts_s), Integer(id_s)]
  end

  def next_cursor_for(relation)
    last = relation.last
    last ? encode_cursor(last) : nil
  end

  def prev_cursor_for(relation)
    first = relation.first
    first ? encode_cursor(first) : nil
  end
end
