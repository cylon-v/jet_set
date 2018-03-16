class Notifier
  def initialize(attrs = {}, notification_service)
    super(attrs)

    @notification_service = notification_service
  end

  def call
    super

    @notification_service.notify
  end
end