# frozen_string_literal: true

# Class extracted from name controller.
class NamesController::Index::Utilities::CoreArgsFilter
  attr_reader :raw_query_string
  def initialize(client_request, raw_query_string)
    @client_request = client_request
    @raw_query_string = raw_query_string
    filter_raw_query_string
  end

  def filter_raw_query_string
    @raw_query_string = 
    @raw_query_string.delete(' ')
                    .delete("\n")
                    .sub(/search_term_placeholder/, @client_request.search_term || '')
                    .sub(/"scientific_name_placeholder"/, @client_request.scientific_name || '')
                    .sub(/"scientific_autonym_name_placeholder"/, @client_request.scientific_autonym_name || '')
                    .sub(/"scientific_hybrid_name_placeholder"/, @client_request.scientific_hybrid_name || '')
                    .sub(/"cultivar_name_placeholder"/, @client_request.cultivar_name || '')
                    .sub(/"common_name_placeholder"/, @client_request.common_name || '')
  end
end