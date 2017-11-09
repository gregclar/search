# frozen_string_literal: true

# Class extracted from name controller.
class NameController::QueryRequest
  def initialize(search_params)
    @params = search_params
  end
  
  def inspect
    'hello'
  end

  def search?
    search_term.present?
  end

  def search_term
    @params[:q].gsub(/ *$/, "")
  end

  def name_type
    @params[:name_type]
  end

  def limit
    @params[:limit] || DEFAULT_LIMIT
  end

  def details?
    @params[:show_details].present? && @params[:show_details] == "show"
  end
  alias show_details details?

  def list?
    !details?
  end

  def family?
    @params[:show_family].present? && @params[:show_family] == "show"
  end

  def links?
    @params[:show_links].present? && @params[:show_links] == "show"
  end
end
