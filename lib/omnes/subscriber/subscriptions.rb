# frozen_string_literal: true

module Omnes
  module Subscriber
    # Collection of {Omnes::Subscription}
    class Subscriptions
      # @!attribute [r] subscriptions
      #   @return [Array<Omnes::Subscription>] All subscriptions
      # @api private
      def initialize(subscriptions:)
        @subscriptions = subscriptions
      end

      # Method names subscribed to a given event name
      #
      # @param event_name [Symbol]
      #
      # @return [Array<Symbol>]
      def method_names(event_name:)
        subscriptions.filter_map do |subscription|
          (subscription.event_name == event_name) && subscription.callback.name
        end
      end

      # Event names subscribed by a given method
      #
      # @param method_name [Symbol]
      #
      # @return [Array<Symbol>]
      def event_names(method_name:)
        subscriptions.filter_map do |subscription|
          (subscription.callback.name == method_name) && subscription.event_name
        end
      end

      # Wrapped subscriptions
      #
      # @param event_name [Symbol] Limit to those subscribed to given event name
      # @param method_name [Symbol] Limit to those subscribed by means of given method name
      #
      # @return [Array<Omnes::Subscription>] All subscriptions
      def subscriptions(event_name: nil, method_name: nil)
        @subscriptions.yield_self do |subs|
          event_name ? subscriptions_for_event_name(subs, event_name) : subs
        end.yield_self do |subs|
          method_name ? subscriptions_for_method_name(subs, method_name) : subs
        end
      end

      private

      def subscriptions_for_event_name(subscriptions, event_name)
        subscriptions.select { |subscriber| subscriber.event_name == event_name }
      end

      def subscriptions_for_method_name(subscriptions, method_name)
        subscriptions.select { |subscriber| subscriber.callback.name == method_name }
      end
    end
  end
end
