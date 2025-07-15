class WelcomeEmailJob < ApplicationJob
  queue_as :default

  def perform(user_id)
    user = User.find(user_id)
    WelcomeMailer.welcome_email(user).deliver_now!
  rescue ActiveRecord::RecordNotFound => e
    Rails.logger.error "User not found for welcome email: #{user_id}"
  rescue => e
    Rails.logger.error "Error sending welcome email to user #{user_id}: #{e.message}"
    raise e
  end
end 