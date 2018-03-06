# frozen_string_literal: true

# Class extracted from name controller.
class NameCheckController::Index::ClientRequest::RunSearch::Query
  def initialize(client_request)
    @client_request = client_request
  end

  def query_string
    NameCheckController::Index::ClientRequest::Utilities::CoreArgsFilter.new(@client_request, raw_query_string).raw_query_string
  end

  def raw_query_string
    base_raw_query_string
  end

  def base_raw_query_string
    <<~HEREDOC
      {
        name_check(#{NameCheckController::Index::ClientRequest::Utilities::CoreArgs.new.core_args})
        {
          results_count,
          results
          {
            search_term,
            found,
            index,
            matched_name_id,
            matched_name_full_name,
            matched_name_family_name
          }
        }
      }
    HEREDOC
  end
end
