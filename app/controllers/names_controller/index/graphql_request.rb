# frozen_string_literal: true

# Class extracted from name controller.
class NamesController::Index::GraphqlRequest
  DATA_SERVER = Rails.configuration.data_server
  def initialize(client_request)
    @client_request = client_request
  end

  def debug(s)
    Rails.logger.debug('==============================================')
    Rails.logger.debug("NamesController::Index::GraphqlRequest: #{s}")
    Rails.logger.debug('==============================================')
  end

  def result
    response = HTTParty.post("#{DATA_SERVER}/v1",
                         body: body,
                         timeout: @client_request.timeout)
    Rails.logger.error(response.code) unless response.code == 200
    Rails.logger.error(response.to_s)  unless response.code == 200
    #debug(response.to_s)
    JSON.parse(response.to_s, object_class: OpenStruct)
  end

  def body
    { query: graphql_query_string }
  end

  def graphql_query_string
    if @client_request.just_count?
      debug('Just count')
      NamesController::Index::CountQuery.new(@client_request).query_string
    elsif @client_request.details?
      debug('Details')
      NamesController::Index::DetailQuery.new(@client_request).query_string
    else
      debug('List')
      NamesController::Index::ListQuery.new(@client_request).query_string
    end
  end
end
