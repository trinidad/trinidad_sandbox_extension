require 'ostruct'

module Trinidad
  module Sandbox
    class ApplicationContext
      def self.dump(context)
        app_context = OpenStruct.new
        app_context.parameters = {}

        context.findParameters().each do |name|
          app_context.parameters[name] = context.findParameter(name)
        end

        context_storage[context.name] = app_context
      end

      def self.load(context)
        if context_storage.has_key?(context.name)
          app_context = context_storage[context.name]

          app_context.parameters.each do |k, v|
            context.addParameter(k, v)
          end
        end
      end

      private
      def self.context_storage
        @@context_storage ||= {}
      end
    end
  end
end

