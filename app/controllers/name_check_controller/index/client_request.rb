# frozen_string_literal: true

# Class extracted from name controller.
# This is the client's request (interpreted).
class NameCheckController::Index::ClientRequest
  attr_reader :params
  MAX_LIST_LIMIT = 500
  def initialize(params)
    @params = params
  end

  def any_type_of_search?
    search_term.present?
  end

  def search_results
    RunSearch.new(self).result
  end

  def search_term
    @params[:q]
  end

  def names_as_array_of_strings
    return "[]" if search_term.blank?
    names = ''
    search_term.split(/[\r\n]+/).each do |name|
      names = names + '"' + name + '",'
    end
    '[' + names.chop + ']'
  end

  def list?
    @params[:list_or_tabular] == 'list'
  end

  def xtabular?
    if @params.has_key?(:list_or_tabular)
      @params[:list_or_tabular] == 'tabular' || !@params.has_key?(:list_or_tabular)
    else
      true
    end
  end

  def tabular?
    @params[:list_or_tabular] == 'tabular' || @params[:list_or_tabular] == nil
  end

  def details?
    false
  end

  # We don't want limit of zero unless it is a count request.
  def limit
    return 0 if just_count?
    limit = @params[:limit_per_page].to_i
    limit = 1 if limit < 1
    [limit, MAX_LIST_LIMIT].min
  end

  def offset
    [@params[:offset].to_i, 0].max
  end

  def just_count?
    @params[:list_or_count] == 'count'
  end

  def timeout
    TimeoutCalculator.new(self).timeout
  end

  def no_search_message
    return [] if any_type_of_search?
    return [] if @params.size < 3
    ["No search", %(Please choose at least one of "Accepted Names", "Excluded Names", or "Cross References")]
  end
end
