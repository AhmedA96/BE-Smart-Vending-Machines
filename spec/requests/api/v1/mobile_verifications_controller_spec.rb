# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V1::MobileVerificationsController, type: :request do
  let(:application) { create(:oauth_application) }
  let(:access_token) { create(:doorkeeper_access_token, application: application, resource_owner_id: nil) }
  let(:headers) { { Authorization: "Bearer #{access_token.token}" } }
  let(:mobile_number) { '+971555234' }

  describe 'POST /api/v1/mobile_verifications/send_verification_code' do
    let!(:user) { users(:john_doe) }

    context 'when user exists and code is sent successfully' do
      before do
        allow(User).to receive(:find_by).with(mobile_number: mobile_number).and_return(user)
        allow(Verification::Mobile).to receive(:send_code).with(mobile_number, user).and_return(true)
      end

      it 'returns ok status' do
        post '/api/v1/mobile_verifications/send_code',
             params: { mobile_number: mobile_number },
             headers: headers

        expect(response).to have_http_status(:ok)
      end
    end

    context 'when user does not exist' do
      before do
        allow(User).to receive(:find_by).with(mobile_number: mobile_number).and_return(nil)
      end

      it 'returns not_found status' do
        post '/api/v1/mobile_verifications/send_code',
             params: { mobile_number: mobile_number },
             headers: headers

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'POST /api/v1/mobile_verifications/verify_code' do
    let!(:user) { users(:john_doe) }
    let(:verification_code) { '123456' }
    let!(:mobile_verification) { mobile_verifications(:one) }

    context 'when verification is successful' do
      before do
        allow(User).to receive(:find_by).with(mobile_number: mobile_number).and_return(user)
        allow(MobileVerification).to receive(:find_by).with(
          mobile_number: mobile_number,
          code: verification_code,
          user_id: user.id
        ).and_return(mobile_verification)
        allow(mobile_verification).to receive(:expired?).and_return(false)
        allow(mobile_verification).to receive(:update!)
        allow(user).to receive(:update!)
      end

      it 'returns ok status' do
        post '/api/v1/mobile_verifications/verify_code',
             params: { mobile_number: mobile_number, verification_code: verification_code },
             headers: headers

        expect(response).to have_http_status(:ok)
      end
    end

    context 'when verification code is invalid' do
      before do
        allow(User).to receive(:find_by).with(mobile_number: mobile_number).and_return(user)
        allow(MobileVerification).to receive(:find_by).with(
          mobile_number: mobile_number,
          code: verification_code,
          user_id: user.id
        ).and_return(nil)
      end

      it 'returns unprocessable_content status' do
        post '/api/v1/mobile_verifications/verify_code',
             params: { mobile_number: mobile_number, verification_code: verification_code },
             headers: headers

        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context 'when user does not exist' do
      before do
        allow(User).to receive(:find_by).with(mobile_number: mobile_number).and_return(nil)
      end

      it 'returns not_found status' do
        post '/api/v1/mobile_verifications/verify_code',
             params: { mobile_number: mobile_number, verification_code: verification_code },
             headers: headers

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
