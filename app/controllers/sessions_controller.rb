# frozen_string_literal: true

require_relative '../services/lundimatin_api_client'

class SessionsController < ApplicationController
  def new
  end
  
  def create
    username = params[:username]
    password = params[:password]
    
    if username.blank? || password.blank?
      flash.now[:alert] = 'Please enter both username and password'
      render :new, status: :unprocessable_entity
      return
    end
    
    begin
      api_client = LundimatinAPIClient.new(username, password)
      response = api_client.authenticate
      
      session[:api_token] = response['datas']['token']
      session[:username] = username
      
      redirect_to contacts_path, notice: 'Login successful!'
    rescue LundimatinAPIClient::AuthenticationError => e
      flash.now[:alert] = "Login failed: #{e.message}"
      render :new, status: :unprocessable_entity
    rescue LundimatinAPIClient::APIError => e
      flash.now[:alert] = "API Error: #{e.message}"
      render :new, status: :unprocessable_entity
    rescue StandardError => e
      flash.now[:alert] = "Unexpected error: #{e.message}"
      render :new, status: :unprocessable_entity
    end
  end
  
  def destroy
    session[:api_token] = nil
    session[:username] = nil
    redirect_to login_path, notice: 'Logged out successfully'
  end
end

