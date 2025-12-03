# frozen_string_literal: true

require_relative '../services/lundimatin_api_client'

class ContactsController < ApplicationController
  before_action :require_authentication
  before_action :initialize_api_client
  before_action :load_contact, only: [:show, :edit, :update]
  
  SEARCHABLE_FIELDS = %w[nom adresse ville tel email code_postal].freeze
  DEFAULT_SORT = '-nom'.freeze
  
  def index
    @search_term = params[:nom] || params[:search]
    
    begin
      search_params = build_search_params
      response = @api_client.get_clients(search_params)
      
      all_contacts = extract_contacts_from_response(response)
      @warnings = response['warnings'] || []
      
      @contacts = filter_contacts(all_contacts, @search_term)
      
    rescue LundimatinAPIClient::APIError => e
      handle_search_error(e)
    rescue StandardError => e
      handle_search_error(e)
    end
  end
  
  def show
  end
  
  def edit
  end
  
  def update
    # Validate params before processing
    validation_errors = validate_contact_params(params[:contact] || {})
    
    if validation_errors.any?
      flash[:alert] = validation_errors.join(', ')
      render :edit, status: :unprocessable_entity
      return
    end
    
    begin
      update_params = build_update_params
      @api_client.update_client(@contact_id, update_params)
      
      flash[:notice] = 'Contact updated successfully'
      redirect_to contact_path(@contact_id)
    rescue LundimatinAPIClient::APIError => e
      flash[:alert] = "Update error: #{e.message}"
      render :edit, status: :unprocessable_entity
    rescue StandardError => e
      flash[:alert] = "Error: #{e.message}"
      render :edit, status: :unprocessable_entity
    end
  end
  
  private
  
  def require_authentication
    unless session[:api_token].present?
      redirect_to login_path, alert: 'Please log in'
    end
  end
  
  def initialize_api_client
    @api_client = LundimatinAPIClient.new(session[:username] || 'user', 'dummy')
    @api_client.instance_variable_set(:@token, session[:api_token])
  end
  
  def load_contact
    @contact_id = params[:id]
    
    begin
      response = @api_client.get_client(@contact_id)
      @contact = response['datas']
    rescue LundimatinAPIClient::NotFoundError => e
      flash[:alert] = "Contact not found: #{e.message}"
      redirect_to contacts_path
    rescue LundimatinAPIClient::APIError => e
      flash[:alert] = "Error: #{e.message}"
      redirect_to contacts_path
    end
  end
  
  def build_search_params
    {
      fields: SEARCHABLE_FIELDS.join(','),
      sort: params[:sort] || DEFAULT_SORT
    }.tap do |params_hash|
      params_hash[:limit] = params[:limit] if params[:limit].present?
    end
  end
  
  def extract_contacts_from_response(response)
    response['datas'] || response['data'] || []
  end
  
  def filter_contacts(contacts, search_term)
    return contacts unless search_term.present?
    
    search_term_downcase = search_term.downcase
    contacts.select do |contact|
      SEARCHABLE_FIELDS.any? do |field|
        contact[field].to_s.downcase.include?(search_term_downcase)
      end
    end
  end
  
  def build_update_params
    contact_params = params[:contact] || {}
    {
      nom: contact_params[:nom],
      tel: contact_params[:tel],
      email: contact_params[:email],
      adresse: contact_params[:adresse],
      code_postal: contact_params[:code_postal],
      ville: contact_params[:ville]
    }.select { |_key, value| value.present? }
  end
  
  def handle_search_error(error)
    @contacts = []
    flash.now[:alert] = "Search error: #{error.message}"
  end
  
  def validate_contact_params(contact_params)
    errors = []
    
    # Validate telephone: only numbers
    if contact_params[:tel].present?
      unless contact_params[:tel].match?(/\A\d+\z/)
        errors << 'Telephone must contain only numbers'
      end
    end
    
    # Validate code postal: only numbers
    if contact_params[:code_postal].present?
      unless contact_params[:code_postal].match?(/\A\d+\z/)
        errors << 'Postal code must contain only numbers'
      end
    end
    
    # Validate email: must contain @
    if contact_params[:email].present?
      unless contact_params[:email].include?('@')
        errors << 'Email must contain @ symbol'
      end
    end
    
    errors
  end
end


