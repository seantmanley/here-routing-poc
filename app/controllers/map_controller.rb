class MapController < ApplicationController
  wrap_parameters false
  
  def index
  end

  def route
    result = Here::Routing.call(**route_params.to_h.symbolize_keys)
    render json: result
  rescue => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def geocode
    result = Here::Geocoding.call(**geocode_params.to_h.symbolize_keys)
    render json: result
  rescue => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  private
  def route_params
    params.permit(:origin, :destination, :mode)
  end

  def geocode_params
    params.permit(:address)
  end
end