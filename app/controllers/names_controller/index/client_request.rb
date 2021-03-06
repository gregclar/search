# frozen_string_literal: true

# Class extracted from name controller.
class NamesController::Index::ClientRequest
  DEFAULT_LIMIT = 50
  MAX_LIST_LIMIT = Rails.configuration.default_list_size_limit
  MAX_DETAILS_LIMIT = Rails.configuration.default_details_size_limit
  AUTO_TRAILING_WILDCARD = true

  def initialize(params, session_editor)
    @params = params
    @session_editor = session_editor
  end

  def any_type_of_search?
    search_term.present?
  end

  def search_term
    return nil unless @params[:q].present?
    if AUTO_TRAILING_WILDCARD
      add_trailing_wildcard(@params[:q].strip)
    else
      @params[:q].strip
    end
  end

  def add_trailing_wildcard(string)
    return string if string =~ /[*%]$/
    return string.chop if string =~ /!$/ # user doesn't want wildcard
    string.sub(/$/, '*')
  end

  def scientific_named_hybrid_name
    if @params[:scientific_named_hybrid_name] == '1'
      'true'
    else
      'false'
    end
  end

  def scientific_autonym_name
    scientific?.to_s
  end

  def scientific?
    %w[scientific all scientific-or-cultivar].include?(@params[:name_type]).to_s
  end

  # We don't want limit of zero unless it is a count request.
  def limit
    return 0 if just_count?
    limit = if list?
              @params[:limit_per_page_for_list].to_i
            else
              @params[:limit_per_page_for_details].to_i
            end
    limit = 1 if limit < 1
    [limit, MAX_LIST_LIMIT].min
  end

  def offset
    [@params[:offset].to_i, 0].max
  end

  def just_count?
    @params[:list_or_count] == 'count'
  end

  # Intention: test that no search has been requested.
  # Method: searches spawn lots of params, so make sure not many params
  def no_search_requested?
    @params.length < 4
  end

  def details?
    (@params[:show_details].present? && @params[:show_details] == '1') ||
    (@session_editor && no_search_requested?)
  end
  alias show_details details?

  def list?
    !details?
  end

  def family?
    (@params[:show_family].present? && @params[:show_family] == '1') ||
    (@session_editor && no_search_requested?)
  end

  def order_by_name?
    !family?
  end

  def order_by_name_within_family?
    family?
  end

  def cultivar_name
    (@params[:cultivar_name] == '1').to_s
  end

  def common_name
    (@params[:common_name] == '1').to_s
  end

  def scientific_name
    (@params[:scientific_name] == '1').to_s
  end

  def links?
    (@params[:show_links].present? && @params[:show_links] == '1') ||
    (@session_editor && no_search_requested?)
  end

  def timeout
    TimeoutCalculator.new(self).timeout
  end

  def content_partial
    "name_#{details? ? 'detail' : 'list'}"
  end
end
