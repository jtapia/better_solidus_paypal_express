FactoryBot.define do
  factory :paypal_express_gateway, class: 'Spree::Gateway::PayPalExpress' do
    name 'Paypal Express'
    active true
  end
end
