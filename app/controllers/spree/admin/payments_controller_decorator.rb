Spree::Admin::PaymentsController.class_eval do
  def paypal_refund
    if request.get?
      if @payment.source.state == 'refunded'
        flash[:error] = Spree.t('paypal.already_refunded')
        redirect_to admin_order_payment_path(@order, @payment)
      end
    elsif request.post?
      response = @payment.payment_method.refund(@payment, params[:refund_amount])
      if response.success?
        flash[:success] = Spree.t('paypal.refund_successful')
        redirect_to admin_order_payments_path(@order)
      else
        flash.now[:error] = Spree.t('paypal.refund_unsuccessful') + " (#{response.errors.first.long_message})"
        render
      end
    end
  end
end
