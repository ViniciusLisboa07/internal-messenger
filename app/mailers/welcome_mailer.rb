class WelcomeMailer < ApplicationMailer
  def welcome_email(user)
    @user = user
    @welcome_url = "#{Rails.application.config.action_mailer.default_url_options[:host]}:#{Rails.application.config.action_mailer.default_url_options[:port]}"
    
    mail(
      to: @user.email,
      subject: "Bem-vindo ao Internal Messenger!"
    )
  end
end 