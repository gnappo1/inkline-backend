class NotesController < ApplicationController
  before_action :bounce_if_not_logged_in
  before_action :find_note, only: [:show, :update, :destroy]

  def index
    notes = Note.order(created_at: :desc)
    render json: notes, status: 200
  end

  def show
    render json: {msg: "Not Found - could not locate note with id ##{params[:id]}"}, status: 404 unless @note
    render json: {msg: "Unauthorized"}, status: 403 unless owns?(@note) || @note.public

    render json: @note, status: 200
  end

  def create
    note = @current_user.notes.new(note_params)
    if note.save
      render json: note, status: 201
    else
      render json: {msg: note.errors}, status: 400
    end
  end

  def update
    render json: {msg: "Not Found - could not locate note with id ##{params[:id]}"}, status: 404 unless @note
    render json: {msg: "Unauthorized"}, status: 403 unless owns?(@note) || @note.public

    if @note.update(note_params)
      render json: @note, status: 200
    else
      render json: {msg: @note.errors}, status: 400
    end
  end

  def destroy
    return render json: { error: "Not found" }, status: 404 unless @note
    return render json: { error: "Unauthorized" }, status: 403 unless owns?(@note)

    @note.destroy
    head 204
  end

  private

  def note_params
    params.require(:note).permit(:title, :body, :public)
  end

  def find_note
    @note = Note.find_by(id: params[:id])
  end

  def owns?(note)
    note.user_id == @current_user.id
  end
end
