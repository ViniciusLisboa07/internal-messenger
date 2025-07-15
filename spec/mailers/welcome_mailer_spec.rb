require 'rails_helper'

RSpec.describe WelcomeMailer, type: :mailer do
  let(:user) { create(:user, name: 'João Silva', email: 'joao@example.com') }

  describe 'welcome_email' do
    let(:mail) { WelcomeMailer.welcome_email(user) }

    it 'renders the headers' do
      expect(mail.subject).to eq('Bem-vindo ao Internal Messenger!')
      expect(mail.to).to eq([user.email])
      expect(mail.from).to eq(['from@example.com'])
    end

    it 'renders the body' do
      expect(mail.body.encoded).to match('Olá, João Silva!')
      expect(mail.body.encoded).to match('Bem-vindo ao Internal Messenger!')
      expect(mail.body.encoded).to match('joao@example.com')
    end

    it 'includes the welcome URL' do
      expect(mail.body.encoded).to include('localhost:3000')
    end
  end
end 