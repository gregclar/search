# frozen_string_literal: true

# Superclass for controllers.
class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  before_action :start_timer, :settings, :ranks

  rescue_from StandardError do |exception|
    logger.error("Rescued StandardError: #{exception}")
    @error = exception
    exception.backtrace.each { |b| logger.error(b) }
    render :error
  end

  private

  def start_timer
    @start_time = Time.now
  end

  # Make name label and tree label available 
  # in views - in tests too.
  def settings
    @setting = Setting.new
    @name_label = @setting.name_label
    @tree_label = @setting.tree_label
  end

  def ranks
    @rank_options = Rank.new.options
  end

  def timeout
    84
  end
end
