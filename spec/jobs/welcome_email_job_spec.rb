require 'rails_helper'

RSpec.describe WelcomeEmailJob, type: :job do
  let(:user) { create(:user) }

  describe '#perform' do
    it 'sends welcome email to the user' do
      expect {
        WelcomeEmailJob.perform_now(user.id)
      }.to change { ActionMailer::Base.deliveries.count }.by(1)

      email = ActionMailer::Base.deliveries.last
      expect(email.to).to eq([user.email])
      expect(email.subject).to eq('Bem-vindo ao Internal Messenger!')
    end

    it 'handles non-existent user gracefully' do
      expect {
        WelcomeEmailJob.perform_now(999999)
      }.not_to raise_error
    end

    it 'logs error when user is not found' do
      allow(Rails.logger).to receive(:error)
      
      WelcomeEmailJob.perform_now(999999)
      
      expect(Rails.logger).to have_received(:error).with("User not found for welcome email: 999999")
    end
  end

  describe 'async execution' do
    it 'enqueues the job' do
      expect {
        WelcomeEmailJob.perform_later(user.id)
      }.to have_enqueued_job(WelcomeEmailJob).with(user.id)
    end
  end
end 