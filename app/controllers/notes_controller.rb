class NotesController < ApplicationController
  before_action :bounce_if_not_logged_in
  before_action :find_note, only: [:update, :destroy]

  def index
    render_jsonapi(@current_user.notes.recent, serializer: NoteSerializer)
  end

  def create
    permitted = note_params.dup
    names = Array(permitted.delete(:categories))
              .map { |s| s.to_s.strip }
              .reject(&:blank?)
              .uniq
              .first(10)
  
    note = @current_user.notes.new(permitted)
  
    ActiveRecord::Base.transaction do
      note.save!
  
      cats = names.map do |n|
        Category.where('LOWER(name) = ?', n.downcase).first_or_create!(name: n)
      end
      note.categories = cats 
      note.save!    
    end
  
    render_jsonapi(note, serializer: NoteSerializer, status: 201)
  
  rescue ActionController::ParameterMissing => e
    render json: { error: e.message }, status: 400
  rescue ActiveRecord::RecordInvalid => _
    render json: { errors: note.errors.full_messages }, status: 422
  end

  def update
    return render(json: { error: "Not found" }, status: 404) unless @note
    return render(json: { error: "Unauthorized" }, status: 403) unless owns?(@note)

    cat_names =
      if params[:note].key?(:categories)
        Array(params[:note][:categories])
          .map { |s| s.to_s.strip }
          .reject(&:blank?)
      else
        nil
      end

    ActiveRecord::Base.transaction do
      @note.update!(note_params.except(:categories))

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
