require 'spec_helper'

describe Spree::Gateway::PayPalExpress do
  let!(:gateway) { create(:paypal_express_gateway) }
  let(:source) do
    Spree::PaypalExpressCheckout.new(token: 'fake_token',
      payer_id: 'fake_payer_id')
  end
  let(:payment) do
    create(:payment, payment_method: gateway, amount: 10, source: source)
  end
  let(:provider) { double('Provider') }
  let(:pp_details_request) { double }
  let(:pp_details_response) do
    double(:get_express_checkout_details_response_details =>
      double(:PaymentDetails => {
        :OrderTotal => {
          :currencyID => 'USD',
          :value => '10.00'
        }
    }))
  end
  let(:success_pp_response) { double('pp_response', :success? => true) }
  let(:error_pp_response) do
    double('pp_response',
      success?: false,
      errors: [double('pp_response_error',
        long_message: 'An error goes here.')])
  end
  let(:payload) do
    {
      :DoExpressCheckoutPaymentRequestDetails => {
        :PaymentAction => 'Sale',
        :Token => 'fake_token',
        :PayerID => 'fake_payer_id',
        :PaymentDetails => pp_details_response
          .get_express_checkout_details_response_details.PaymentDetails
      }
    }
  end

  before do
    allow(gateway).to receive(:provider).and_return(provider)
    allow(provider).to receive(:build_get_express_checkout_details)
      .and_return(pp_details_request)
    allow(provider).to receive(:get_express_checkout_details)
      .and_return(pp_details_response)
    allow(provider).to receive(:build_do_express_checkout_payment)
      .and_return(payload)
  end

  context 'payment purchase' do
    # Test for #11
    it 'succeeds' do
      allow(success_pp_response)
        .to receive_message_chain(:do_express_checkout_payment_response_details,
          :payment_info, :first, :transaction_id).and_return('12345')
      allow(provider).to receive(:do_express_checkout_payment)
        .and_return(success_pp_response)
      expect{ payment.purchase! }.not_to raise_error
    end

    # Test for #4
    it 'fails' do
      allow(provider).to receive(:do_express_checkout_payment)
        .and_return(error_pp_response)
      expect{ payment.purchase! }
        .to raise_error(Spree::Core::GatewayError, 'An error goes here.')
    end
  end
end
