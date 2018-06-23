require 'spec_helper'

feature 'PayPal', js: true do
  let!(:store) { create(:store) }
  let!(:country) { create(:country, states_required: true) }
  let!(:state) { create(:state, country: country) }
  let!(:shipping_method) { create(:shipping_method) }
  let!(:stock_location) { create(:stock_location) }
  let!(:product) { create(:product, name: 'iPad') }
  let!(:zone) { create(:zone) }
  let!(:gateway) { create(:paypal_express_gateway) }

  before do
    gateway.preferences = {
      preferred_login: "pp_api1.ryanbigg.com",
      preferred_password: "1383066713",
      preferred_signature: "An5ns1Kso7MWUdW4ErQKJJJ4qi4-Ar-LpzhMJL0cu8TjM8Z2e1ykVg5B",
    }
  end

  xit 'pays for an order successfully' do
    add_to_cart(product)
    click_button 'Checkout'
    fill_in_guest
    fill_in_billing
    click_button "Save and Continue"
    # Delivery step doesn't require any action
    click_button "Save and Continue"
    find("#paypal_button").click
    switch_to_paypal_login
    login_to_paypal
    click_button "Pay Now"
    expect(page).to have_content("Your order has been processed successfully")

    expect(Spree::Payment.last.source.transaction_id).to_not be_blank
  end

  xcontext "with 'Sole' solution type" do
    before do
      gateway.preferred_solution = 'Sole'
    end

    it "passes user details to PayPal" do
      add_to_cart(product)
      click_button 'Checkout'
      within("#guest_checkout") do
        fill_in "Email", with: "test@example.com"
        click_button 'Continue'
      end
      fill_in_billing
      click_button "Save and Continue"
      # Delivery step doesn't require any action
      click_button "Save and Continue"
      choose('order[payments_attributes][][payment_method_id]').last
      find("#paypal_button").click

      login_to_paypal
      click_button "Pay Now"

      expect(page).to have_selector('[data-hook=order-bill-address] .fn', text: 'Test User')
      expect(page).to have_selector('[data-hook=order-bill-address] .adr', text: '1 User Lane')
      expect(page).to have_selector('[data-hook=order-bill-address] .adr', text: 'Adamsville AL 35005')
      expect(page).to have_selector('[data-hook=order-bill-address] .adr', text: 'United States')
      expect(page).to have_selector('[data-hook=order-bill-address] .tel', text: '555-123-4567')
    end
  end

  xit "includes adjustments in PayPal summary" do
    add_to_cart(product)
    # TODO: Is there a better way to find this current order?
    order = Spree::Order.last
    order.adjustments.create!(amount: -5, label: "$5 off")
    order.adjustments.create!(amount: 10, label: "$10 on")
    visit '/cart'
    within("#cart_adjustments") do
      expect(page).to have_content("$5 off")
      expect(page).to have_content("$10 on")
    end
    click_button 'Checkout'
    fill_in_guest
    fill_in_billing
    click_button "Save and Continue"
    # Delivery step doesn't require any action
    click_button "Save and Continue"
    find("#paypal_button").click

    within_transaction_cart do
      expect(page).to have_content("$5 off")
      expect(page).to have_content("$10 on")
    end

    login_to_paypal

    within_transaction_cart do
      expect(page).to have_content("$5 off")
      expect(page).to have_content("$10 on")
    end

    click_button "Pay Now"

    within("[data-hook=order_details_adjustments]") do
      expect(page).to have_content("$5 off")
      expect(page).to have_content("$10 on")
    end
  end

  xcontext "line item adjustments" do
    let(:promotion) { Spree::Promotion.create(name: "10% off") }

    before do
      calculator = Spree::Calculator::FlatPercentItemTotal.new(preferred_flat_percent: 10)
      action = Spree::Promotion::Actions::CreateItemAdjustments.create(calculator: calculator)
      promotion.actions << action
    end

    it "includes line item adjustments in PayPal summary" do
      add_to_cart(product)
      # TODO: Is there a better way to find this current order?
      order = Spree::Order.last
      expect(order.line_item_adjustments.count).to == 1

      visit '/cart'
      within("#cart_adjustments") do
        expect(page).to have_content("10% off")
      end
      click_button 'Checkout'
      within("#guest_checkout") do
        fill_in "Email", with: "test@example.com"
        click_button 'Continue'
      end
      fill_in_billing
      click_button "Save and Continue"
      # Delivery step doesn't require any action
      click_button "Save and Continue"
      find("#paypal_button").click

      within_transaction_cart do
        expect(page).to have_content("10% off")
      end

      login_to_paypal
      click_button "Pay Now"

      within("[data-hook=order_details_price_adjustments]") do
        expect(page).to have_content("10% off")
      end
    end
  end

  # Regression test for #10
  xcontext "will skip $0 items" do
    let!(:product2) { create(:product, name: 'iPod') }

    it do
      add_to_cart(product)
      add_to_cart(product2)

      # TODO: Is there a better way to find this current order?
      order = Spree::Order.last
      order.line_items.last.update_attribute(:price, 0)
      click_button 'Checkout'
      within("#guest_checkout") do
        fill_in "Email", with: "test@example.com"
        click_button 'Continue'
      end
      fill_in_billing
      click_button "Save and Continue"
      # Delivery step doesn't require any action
      click_button "Save and Continue"
      find("#paypal_button").click

      within_transaction_cart do
        expect(page).to have_content('iPad')
        expect(page).to_not have_content('iPod')
      end

      login_to_paypal

      within_transaction_cart do
        expect(page).to have_content('iPad')
        expect(page).to_not have_content('iPod')
      end

      click_button "Pay Now"

      within("#line-items") do
        expect(page).to have_content('iPad')
        expect(page).to have_content('iPod')
      end
    end
  end

  xcontext "can process an order with $0 item total" do
    before do
      # If we didn't do this then the order would be free and skip payment altogether
      calculator = Spree::ShippingMethod.first.calculator
      calculator.preferred_amount = 10
      calculator.save
    end

    it do
      add_to_cart(product)
      # TODO: Is there a better way to find this current order?
      order = Spree::Order.last
      order.adjustments.create!(amount: -order.line_items.last.price, label: "FREE iPad ZOMG!")
      click_button 'Checkout'
      within("#guest_checkout") do
        fill_in "Email", with: "test@example.com"
        click_button 'Continue'
      end
      fill_in_billing
      click_button "Save and Continue"
      # Delivery step doesn't require any action
      click_button "Save and Continue"
      find("#paypal_button").click

      login_to_paypal

      click_button "Pay Now"

      within("[data-hook=order_details_adjustments]") do
        expect(page).to have_content('FREE iPad ZOMG!')
      end
    end
  end

  context 'cannot process a payment with invalid gateway details' do
    before do
      gateway.preferred_login = nil
      gateway.save
    end

    it 'returns failed payment process' do
      add_to_cart(product)
      click_button 'Checkout'
      within('#guest_checkout') do
        fill_in 'Email', with: 'test@example.com'
        click_button 'Continue'
      end
      fill_in_billing
      click_button 'Save and Continue'
      # Delivery step doesn't require any action
      click_button 'Save and Continue'
      find('#paypal_button').click
      expect(page).to have_content('PayPal failed.')
    end
  end

  xcontext "can process an order with Tax included prices" do
    let(:tax_rate) { create(:tax_rate, name: 'VAT Tax', amount: 0.1,
                            zone: Spree::Zone.first, included_in_price: true) }
    let(:tax_category) { create(:tax_category, tax_rates: [tax_rate]) }
    let(:product3) { create(:product, name: 'EU Charger', tax_category: tax_category) }
    let(:tax_string) { "VAT Tax 10.0%" }

    # Regression test for #129
    context "on countries where the Tax is applied" do
      before do
        Spree::Zone.first.update_attribute(:default_tax, true)
      end

      it do
        add_to_cart(product3)
        visit '/cart'

        within("#cart_adjustments") do
          expect(page).to have_content("#{tax_string} (Included in Price)")
        end

        click_button 'Checkout'
        fill_in_guest
        fill_in_billing
        click_button "Save and Continue"
        click_button "Save and Continue"
        find("#paypal_button").click

        within_transaction_cart do
          # included taxes should not go on paypal
          expect(page).to_not have_content(tax_string)
        end

        login_to_paypal
        click_button "Pay Now"
        expect(page).to have_content("Your order has been processed successfully")
      end
    end
  end

  xcontext 'as an admin' do
    context 'refunding payments' do
      before do
        stub_authorization!
        visit spree.root_path
        click_link 'iPad'
        click_button 'Add To Cart'
        click_button 'Checkout'
        within('#guest_checkout') do
          fill_in 'Email', with: 'test@example.com'
          click_button 'Continue'
        end
        fill_in_billing
        click_button 'Save and Continue'
        # Delivery step doesn't require any action
        click_button 'Save and Continue'
        find('#paypal_button').click
        switch_to_paypal_login
        login_to_paypal
        click_button('Pay Now')
        expect(page).to have_content('Your order has been processed successfully')

        visit '/admin'
        click_link Spree::Order.last.number
        click_link 'Payments'
        find('#content').find('table').first('a').click # this clicks the first payment
        click_link 'Refund'
      end

      it 'can refund payments fully' do
        click_button 'Refund'
        expect(page).to have_content('PayPal refund successful')

        payment = Spree::Payment.last
        paypal_checkout = payment.source.source
        expect(paypal_checkout.refund_transaction_id).to_not be_blank
        expect(paypal_checkout.refunded_at).to_not be_blank
        expect(paypal_checkout.state).to eql('refunded')
        expect(paypal_checkout.refund_type).to eql('Full')

        # regression test for #82
        within('table') do
          expect(page).to have_content(payment.display_amount.to_html)
        end
      end

      it 'can refund payments partially' do
        payment = Spree::Payment.last
        # Take a dollar off, which should cause refund type to be...
        fill_in 'Amount', with: payment.amount - 1
        click_button 'Refund'
        expect(page).to have_content('PayPal refund successful')

        source = payment.source
        expect(source.refund_transaction_id).to_not be_blank
        expect(source.refunded_at).to_not be_blank
        expect(source.state).to eql('refunded')
        # ... a partial refund
        expect(source.refund_type).to eql('Partial')
      end

      it 'errors when given an invalid refund amount' do
        fill_in 'Amount', with: 'lol'
        click_button 'Refund'
        expect(page).to have_content('PayPal refund unsuccessful (The partial refund amount is not valid)')
      end
    end
  end

  def fill_in_billing
    fill_in :order_bill_address_attributes_firstname, with: 'Test'
    fill_in :order_bill_address_attributes_lastname, with: 'User'
    fill_in :order_bill_address_attributes_address1, with: '1 User Lane'
    # City, State and ZIP must all match for PayPal to be happy
    fill_in :order_bill_address_attributes_city, with: 'Adamsville'
    select 'United States of America', from: :order_bill_address_attributes_country_id
    find('#order_bill_address_attributes_state_id').find(:xpath, 'option[2]').select_option
    fill_in :order_bill_address_attributes_zipcode, with: '35005'
    fill_in :order_bill_address_attributes_phone, with: '555-123-4567'
  end

  def switch_to_paypal_login
    # If you go through a payment once in the sandbox, it remembers your preferred setting.
    # It defaults to the *wrong* setting for the first time, so we need to have this method.
    unless page.has_selector?('#login #email')
      find('#loadLogin').click
    end
  end

  def login_to_paypal
    within('#loginForm') do
      fill_in 'Email', with: 'pp@spreecommerce.com'
      fill_in 'Password', with: 'thequickbrownfox'
      click_button 'Log in to PayPal'
    end
  end

  def within_transaction_cart(&block)
    find('.transactionDetails').click
    within('.transctionCartDetails') { block.call }
  end

  def add_to_cart(product)
    visit spree.root_path
    click_link product.name
    click_button 'Add To Cart'
    sleep(1)
    visit spree.cart_path
  end

  def fill_in_guest
    within('#guest_checkout') do
      fill_in 'Email', with: 'test@example.com'
      click_button 'Continue'
    end
  end
end
