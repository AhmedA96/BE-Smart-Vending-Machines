# frozen_string_literal: true

# # frozen_string_literal: true

# require 'rails_helper'

# RSpec.describe Api::V1::OrdersController, type: :request do
#   let(:user) { users(:john_doe) }
#   let(:order) { orders(:order_001) }
#   let(:application) { create(:oauth_application) }
#   let(:access_token) { create(:doorkeeper_access_token, application: application, resource_owner_id: user.id) }

#   describe 'GET /api/v1/orders' do
#     let!(:user_orders) { [orders(:order_001), orders(:order_003)] }

#     before do
#       allow(user).to receive(:orders).and_return(user_orders)
#     end

#     it 'returns all user orders' do
#       get '/api/v1/orders', headers: { Authorization: "Bearer #{access_token.token}" }

#       expect(response).to have_http_status(:ok)
#     end

#     xit 'calls paginate with user orders' do
#       expect_any_instance_of(Api::V1::OrdersController).to receive(:paginate).with(user_orders)
#       get '/api/v1/orders', headers: { Authorization: "Bearer #{access_token.token}" }
#     end
#   end

#   describe 'GET /api/v1/orders/:id' do
#     let!(:order) { orders(:order_001) }

#     it 'returns the specific order' do
#       get "/api/v1/orders/#{order.id}", headers: { Authorization: "Bearer #{access_token.token}" }

#       expect(response).to have_http_status(:ok)
#     end

#     context 'when order is not found' do
#       it 'returns not found status' do
#         get '/api/v1/orders/999', headers: { Authorization: "Bearer #{access_token.token}" }

#         expect(response).to have_http_status(:not_found)
#       end
#     end
#   end

#   describe 'POST /api/v1/orders' do
#     let(:order_params) do
#       {
#         order: {
#           cart_items: [
#             { variant_id: 1, quantity: 2 },
#             { variant_id: 2, quantity: 1 }
#           ]
#         }
#       }
#     end
#     let(:created_order) { orders(:order_003) }

#     context 'when order creation is successful' do
#       before do
#         allow(Orders::Create).to receive(:call).and_return(created_order)
#       end

#       it 'creates a new order' do
#         post '/api/v1/orders', params: order_params, headers: { Authorization: "Bearer #{access_token.token}" }

#         expect(response).to have_http_status(:created)
#       end

#       it 'calls the Orders::Create service with correct params' do
#         expect(Orders::Create).to receive(:call).with(instance_of(ActionController::Parameters))
#         post '/api/v1/orders', params: order_params, headers: { Authorization: "Bearer #{access_token.token}" }
#       end

#       it 'renders show template' do
#         post '/api/v1/orders', params: order_params, headers: { Authorization: "Bearer #{access_token.token}" }

#         expect(response).to render_template(:show)
#       end
#     end

#     context 'when order creation fails' do
#       let(:error_message) { 'Order creation failed' }

#       before do
#         allow(Orders::Create).to receive(:call).and_raise(StandardError, error_message)
#       end

#       it 'returns bad request status' do
#         post '/api/v1/orders', params: order_params, headers: { Authorization: "Bearer #{access_token.token}" }

#         expect(response).to have_http_status(:bad_request)
#       end
#     end

#     context 'with various parameter formats' do
#       it 'handles empty params' do
#         allow(Orders::Create).to receive(:call).and_return(created_order)
#         post '/api/v1/orders', params: {}, headers: { Authorization: "Bearer #{access_token.token}" }

#         expect(Orders::Create).to have_received(:call).with(instance_of(ActionController::Parameters))
#         expect(response).to have_http_status(:created)
#       end

#       it 'handles params without order key' do
#         allow(Orders::Create).to receive(:call).and_return(created_order)
#         params = { variant_id: 1, quantity: 2 }
#         post '/api/v1/orders', params: params, headers: { Authorization: "Bearer #{access_token.token}" }

#         expect(Orders::Create).to have_received(:call).with(instance_of(ActionController::Parameters))
#         expect(response).to have_http_status(:created)
#       end
#     end
#   end
# end
