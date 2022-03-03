# frozen_string_literal: true

require "omnes/subscriber/errors"
require "omnes/subscriber/subscriptions"

module Omnes
  module Subscriber
    # @api private
    class State
      attr_reader :manual_definitions, :calling_cache

      def initialize(manual_definitions: [], calling_cache: [])
        @manual_definitions = manual_definitions
        @calling_cache = calling_cache
      end

      def call(bus, context)
        raise FrozenSubscriberError if calling_cache.include?([bus, context])

        definitions = manual_definitions + autodiscovered_definitions(bus, context)
        check_duplicates(definitions)
        definitions.each do |event_name, method_name|
          check_method(event_name, method_name, context)
        end

        Subscriptions.new(
          subscriptions: subscribe_definitions(definitions, bus, context)
        ).tap { @calling_cache << [bus, context] }
      end

      def add_manual_definition(event_name, with)
        @manual_definitions << [event_name, with]
      end

      private

      def autodiscovered_definitions(bus, context)
        bus.registry.event_names.filter_map do |event_name|
          candidate = :"on_#{event_name}"
          context.respond_to?(candidate, true) && [event_name, candidate]
        end
      end

      def check_duplicates(events_with_methods)
        duplicates = events_with_methods.group_by(&:itself).filter_map { |k, v| v.count > 1 && k }

        raise DuplicateSubscriptionAttemptError.new(duplicates: duplicates) if duplicates.any?
      end

      def check_method(event_name, method_name, context)
        if context.private_methods.include?(method_name)
          raise PrivateMethodSubscriptionAttemptError.new(event_name: event_name,
                                                          method_name: method_name)
        end
        return if context.methods.include?(method_name)

        raise UnknownMethodSubscriptionAttemptError.new(event_name: event_name,
                                                        method_name: method_name)
      end

      def subscribe_definitions(definitions, bus, context)
        definitions.map do |(event_name, method_name)|
          bus.subscribe(event_name, context.method(method_name))
        end
      end
    end
  end
end
