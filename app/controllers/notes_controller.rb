# require "pry"
class NotesController < ApplicationController
  before_action :bounce_if_not_logged_in
  before_action :find_note, only: [:show, :update, :destroy]

  def index
    # notes = Note.order(created_at: :desc)
    render_jsonapi(@current_user.notes.recent, serializer: NoteSerializer)
  end

  def show
    render json: {msg: "Not Found - could not locate note with id ##{params[:id]}"}, status: 404 unless @note
    render json: {msg: "Unauthorized"}, status: 403 unless owns?(@note) || @note.public

    render_jsonapi(@note, serializer: NoteSerializer)
  end

  def create
    note = @current_user.notes.new(note_params)
    if note.save
      render_jsonapi(note, serializer: NoteSerializer, status: 201)
    else
      render json: {msg: note.errors}, status: 400
    end
  end

  def update
    return render(json: { error: "Not found" }, status: 404) unless @note
    return render(json: { error: "Unauthorized" }, status: 403) unless owns?(@note)

    # Pull category names if they were sent; otherwise leave categories untouched
    cat_names =
      if params[:note].key?(:categories)
        Array(params[:note][:categories])
          .map { |s| s.to_s.strip }
          .reject(&:blank?)
      else
        nil
      end

    ActiveRecord::Base.transaction do
      # Update regular attributes
      @note.update!(note_params.except(:categories))

      # Replace categories by name (find or create, case-insensitive)
      if cat_names
        cats = cat_names.map do |n|
          Category.where("LOWER(name) = ?", n.downcase).first_or_create!(name: n)
        end
        @note.categories = cats
      end
    end

    render_jsonapi(@note, serializer: NoteSerializer, status: 200)
  rescue ActiveRecord::RecordInvalid
    render json: { errors: @note.errors.full_messages }, status: 422
  end

  def destroy
    return render json: { error: "Not found" }, status: 404 unless @note
    return render json: { error: "Unauthorized" }, status: 403 unless owns?(@note)

    @note.destroy
    head 204
  end

  private

  def note_params
    params.require(:note).permit(
      :title, :body, :public,
      categories: []
    )
  end

  def find_note
    @note = Note.find_by(id: params[:id])
  end

  def owns?(note)
    note.user_id == @current_user.id
  end
end
