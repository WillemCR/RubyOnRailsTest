class ApiController < ActionController::API
  def health
    render json: { status: "ok" }
  end

  def ping
    render json: { message: "pong" }
  end
end
