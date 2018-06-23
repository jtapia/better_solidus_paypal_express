require 'spec_helper'

describe Spree::PaypalController do
  before do
    allow(controller).to receive_messages(try_spree_current_user: nil)
    allow(controller).to receive_messages(spree_current_user: nil)
    allow(controller).to receive_messages(current_order: nil)
  end

  context 'when current_order is nil' do
    context 'express' do
      it 'raises ActiveRecord::RecordNotFound' do
        expect{ get :express }.
          to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'confirm' do
      it 'raises ActiveRecord::RecordNotFound' do
        expect{ get :confirm }.
          to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'cancel' do
      it 'raises ActiveRecord::RecordNotFound' do
        expect{ get :cancel }.
          to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
