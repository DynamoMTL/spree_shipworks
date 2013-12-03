module SpreeShipworks
  class UpdateShipment
    include Dsl

    def call(params)
      if params['order'].to_i > SpreeShipworks::PREORDER_ORDER_ID_ADJUSTMENT
        order_id = params['order'].to_i - SpreeShipworks::PREORDER_ORDER_ID_ADJUSTMENT
        preorder = true
      end
      preorder ||= false
      order_id ||= params['order']

      order = Spree::Order.find(order_id)

      if preorder
        shipment = order.shipments.detect { |s| s.shipping_method.name == 'PreOrder - USPS' && s.state == 'ready' && s.tracking.nil? }
      end
      shipment ||= order.shipments.detect { |s| s.shipping_method.name != 'PreOrder - USPS' && s.state == 'ready' && s.tracking.nil? }

      if shipment.try(:update_attributes, { :tracking => params['tracking'] })
        response do |r|
          r.element 'UpdateSuccess'
        end
      else
        Honeybadger.notify(error_response)
        error_response("UNPROCESSIBLE_ENTITY", "Could not update tracking information for Order ##{params['order']}")
      end

    rescue ActiveRecord::RecordNotFound
      error_response("NOT_FOUND", "Unable to find an order with ID of '#{params['order']}'.")
    rescue => error
      error_response("INTERNAL_SERVER_ERROR", error.to_s)
    end
  end
end
