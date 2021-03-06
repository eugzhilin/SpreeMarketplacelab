module Spree
  module Marketplace
    class ListenerController < Spree::Api::BaseController

      def product
      #   product_sku = request.POST["StoreProductId"]
      #
      #   logger.info "Product hook for SKU: #{product_sku}"
      #
      #   spree_product = Spree::Product.joins(:master).where("spree_variants.sku = ?", product_sku)
      #
      #   if spree_product
      #     logger.info "Product with SKU #{product_sku} already exists"
      #   else
      #     logger.info "Product with SKU #{product_sku} not found, creating new product"
      #
      #     marketplace_api = ::Marketplace::Api.instance
      #     marketplace_product = marketplace_api.get_product(product_sku)
      #   end
      #
        @result = "ok"
      end

      def listing
        # listing_id = request.POST["ListingId"]
        product_sku = request.POST["StoreProductId"]

        logger.info "Listing hook for SKU: #{product_sku}"

        marketplace_api = ::Marketplace::Api.instance
        marketplace_api.notify(:listing_updated, product_sku)

        @result = "ok"
      end

      def order
        store_order_id = request.POST["StoreOrderId"]

        order = Spree::Order.find_by!(number: store_order_id)

        @result = "ok"
      end

      def order_dispatched
        store_order_id = request.POST["StoreOrderId"]
        logger.info "Order Dispatched Hook called for StoreOrderId " + store_order_id + " ."
        @result = "ok"

        order = Spree::Order.find_by!(number: store_order_id)


        if @order

        end

        # capture a payment, that would set shipment to ready state
        # Loop through the payments and find one at the correct status
        processed = false;
        order.payments.each do |payment|
          if payment.state == 'pending'
            payment.capture!
            processed = true
            logger.info "Successully captured payment for StoreOrderId " + store_order_id
            break;
          end
        end

        if processed
          # If we successfully proccessed the payment then Ship the order!
          shipment = Spree::Shipment.find_by!(number: order.shipments[0].number)
          unless shipment.shipped?
            shipment.ship!
            logger.info "Successfully shipped StoreOrderId " + store_order_id
          else
            logger.error "Failed to ship StoreOrderId " + store_order_id + " but payment has been taken and udpated. ** this will need to be fixed manually."
          end
        else
            logger.error "Failed to find a pending status payment to capture for StoreOrderId : " + store_order_id + " - ** this will need to be fixing manually."
        end

      end

      private
        def logger
          @logger ||= MarketplaceLogger.new
        end

    end
  end
end