require 'spree_shipworks/orders'

module SpreeShipworks
  class GetOrders
    include Dsl

    def call(params)
      response do |r|
        r.element 'Orders' do |rr|
          ::SpreeShipworks::Orders.since_in_batches(params['start'], params['maxcount']) do |order|
            if order.shipments.size > 1
              order.to_shipworks_xml(rr)

              shipment = order.shipments.detect { |sh| sh.shipping_method.name == 'PreOrder - USPS' }
              if shipment.state == 'ready'
                order.to_shipworks_xml(rr, true)
              end
            else
              order.to_shipworks_xml(rr)
            end
          end
        end
      end
    rescue ArgumentError => error
      error_response("INVALID_VARIABLE", error.to_s + "\n" + error.backtrace.join("\n"))
    rescue => error
      Rails.logger.error(error.to_s)
      Rails.logger.error(error.backtrace.join("\n"))
      error_response("INTERNAL_SERVER_ERROR", error.to_s)
    end
  end
end
