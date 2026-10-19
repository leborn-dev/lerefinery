require 'spec_helper'

RSpec.describe Refinery::AdminController, type: :controller do
  controller(Refinery::AdminController) do
    skip_before_action :force_ssl!, :authenticate_refinery_user!, :restrict_controller
    def index
      session[:security_probe_writes] = session[:security_probe_writes].to_i + 1
      head :ok
    end
  end

  around do |example|
    previous = described_class.allow_forgery_protection
    described_class.allow_forgery_protection = true
    example.run
  ensure
    described_class.allow_forgery_protection = previous
  end

  it 'inherits the module CSRF callback and rejects tokenless writes before the action' do
    expect { post :index }.to raise_error(ActionController::InvalidAuthenticityToken)
    expect(session[:security_probe_writes]).to be_nil
  end

  it 'accepts a valid session token without changing the authentication callbacks' do
    token = controller.send(:form_authenticity_token)
    post :index, params: { authenticity_token: token }
    expect(response).to have_http_status(:ok)
    expect(session[:security_probe_writes]).to eq(1)
  end
end
