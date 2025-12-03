# frozen_string_literal: true

require 'net/http'
require 'json'
require 'uri'
require 'base64'

# Service class for Lundimatin API calls following API_CODING_STANDARDS.md
# Complies with: Basic HTTP Authentication, headers, error handling
class LundimatinAPIClient
  class APIError < StandardError; end
  class AuthenticationError < APIError; end
  class BadRequestError < APIError; end
  class NotFoundError < APIError; end
  class ForbiddenError < APIError; end
  
  ACCEPT_HEADER = 'application/api.rest-v1+json'.freeze
  CONTENT_TYPE_HEADER = 'application/json'.freeze
  CODE_APPLICATION = 'webservice_externe'.freeze
  PASSWORD_TYPE_CLEAR = 0
  
  def initialize(username, password, code_version = '1')
    @username = username
    @password = password
    @code_version = code_version
    @token = nil
  end
  
  # Authenticate and get token
  def authenticate
    uri = URI("#{base_url}auth")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.open_timeout = 10
    http.read_timeout = 10
    
    request = Net::HTTP::Post.new(uri.path)
    set_headers(request, include_content_type: true)
    request.body = {
      username: @username,
      password: @password,
      password_type: PASSWORD_TYPE_CLEAR,
      code_application: CODE_APPLICATION,
      code_version: @code_version
    }.to_json
    
    response = http.request(request)
    handle_response(response) do |data|
      @token = data['token']
      @token
    end
  end
  
  # Get list of clients with filters
  def get_clients(params = {})
    query_string = URI.encode_www_form(params.reject { |_k, v| v.blank? })
    endpoint = query_string.empty? ? 'clients' : "clients?#{query_string}"
    api_call('GET', endpoint)
  end
  
  # Get specific client information
  def get_client(client_id)
    api_call('GET', "clients/#{client_id}")
  end
  
  # Update client
  def update_client(client_id, attributes)
    api_call('PUT', "clients/#{client_id}", attributes)
  end
  
  # Generic API call method
  def api_call(method, endpoint, params = {})
    authenticate unless @token
    
    # Build URI with query string if present
    full_url = "#{base_url}#{endpoint}"
    uri = URI(full_url)
    
    # If GET request and endpoint has query string, keep it
    # Otherwise, add query string from params
    if method.upcase == 'GET' && params.any?
      query_params = params.reject { |_k, v| v.blank? }
      uri.query = URI.encode_www_form(query_params) if query_params.any?
    end
    
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.open_timeout = 10
    http.read_timeout = 10
    
    request_class = case method.upcase
                    when 'GET'
                      Net::HTTP::Get
                    when 'POST'
                      Net::HTTP::Post
                    when 'PUT'
                      Net::HTTP::Put
                    when 'DELETE'
                      Net::HTTP::Delete
                    else
                      raise APIError, "Unsupported HTTP method: #{method}"
                    end
    
    # Use request_uri to include query string
    request_uri = uri.request_uri
    request = request_class.new(request_uri)
    is_post_or_put = ['POST', 'PUT'].include?(method.upcase)
    set_headers(request, include_content_type: is_post_or_put)
    set_authorization(request)
    
    request.body = params.to_json if is_post_or_put
    
    response = http.request(request)
    handle_response(response)
  end
  
  # Check if token exists
  def authenticated?
    !@token.nil?
  end
  
  # Clear token (used when logout or re-authenticate)
  def clear_token
    @token = nil
  end
  
  private
  
  def base_url
    url = ENV['LUNDI_MATIN_BASE_URL'].presence
    raise APIError, 'LUNDI_MATIN_BASE_URL environment variable is not set' unless url
    url
  end
  
  def set_headers(request, include_content_type: false)
    request['Accept'] = ACCEPT_HEADER
    request['Content-Type'] = CONTENT_TYPE_HEADER if include_content_type
  end
  
  def set_authorization(request)
    return unless @token
    
    credentials = Base64.strict_encode64(":#{@token}")
    request['Authorization'] = "Basic #{credentials}"
  end
  
  def handle_response(response)
    data = JSON.parse(response.body)
    
    case response.code.to_i
    when 200, 201
      yield(data['datas']) if block_given?
      data
    when 400
      @token = nil
      raise BadRequestError, data['message'].presence || 'Bad Request. Check parameters and Accept header.'
    when 401
      @token = nil
      raise AuthenticationError, data['message'].presence || 'Unauthorized. Please re-authenticate.'
    when 403
      @token = nil
      raise ForbiddenError, data['message'].presence || 'Forbidden. Invalid token.'
    when 404
      raise NotFoundError, data['message'].presence || 'Not Found'
    when 405
      raise APIError, "Method Not Allowed: #{data['message']}"
    when 410
      raise APIError, "Version Incompatibility: #{data['message']}"
    when 415
      raise APIError, "Unsupported Media Type: #{data['message']}"
    when 500
      raise APIError, "Internal Server Error: #{data['message']}"
    else
      raise APIError, "Unexpected status code: #{response.code}"
    end
  rescue JSON::ParserError => e
    raise APIError, "Invalid JSON response: #{e.message}"
  end
end

