require_relative './tension'

class Accelerator < Extension
  def initialize(attrs = {}, acceleration_service)
    super(attrs)

    @acceleration_service = acceleration_service
  end

  def call
    super

    @acceleration_service.accelerate
  end
end