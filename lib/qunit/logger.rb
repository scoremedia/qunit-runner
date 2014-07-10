module Qunit
  class Logger
    @print_color = !ENV.has_key?('DISABLE_COLOR')
    class << self

      def print(message, color = nil)
        Kernel.print apply_color(message, color)
      end

      def puts(message, color = nil)
        Kernel.puts apply_color(message, color)
      end

      protected

      def apply_color(message, color = nil)
        if !color.nil? && @print_color
          message.send(color.to_sym)
        else
          message
        end
      end

    end
  end
end
