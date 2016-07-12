#  Search for scientific names
class Plants::Taxonomy::Accepted::Search::Accepted
  attr_reader :parsed,
              :results
  SEARCH_TYPE = "Scientific Name".freeze
  def initialize(params, default_show_results_as: "details")
    @parsed = Plants::Taxonomy::Accepted::Search::Parse.new(
      params,
      search_type: SEARCH_TYPE,
      default_show_results_as:
      default_show_results_as)
    @results = simple_name_search
    return unless @results.empty?
    @results = full_name_search
  end

  def simple_name_search
    search.simple_name_like(@parsed.search_term)
  end

  def full_name_search
    search.full_name_like(@parsed.search_term)
  end

  def search
    AcceptedName.accepted
                .ordered
                .includes(:status)
                .includes(:reference)
                .includes(:rank)
                .includes(:instance)
                .includes(:names)
                .includes(:instance_types)
                .includes(:synonyms)
                .includes(:cites)
                .includes(:cite_references)
                .includes(:instance_note_keys)
  end
end
