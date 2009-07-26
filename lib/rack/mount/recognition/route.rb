require 'rack/mount/prefix'

module Rack
  module Mount
    module Recognition
      module Route #:nodoc:
        attr_reader :keys

        def initialize(*args)
          super

          # TODO: Don't explict check for :path_info condition
          if @conditions.has_key?(:path_info) &&
              !@conditions[:path_info].anchored?
            @app = Prefix.new(@app)
          end

          @keys = generate_keys
        end

        def call(req)
          env = req.env

          routing_args = @defaults.dup
          if @conditions.all? { |method, condition|
            value = req.send(method)
            if m = value.match(condition.to_regexp)
              matches = m.captures
              condition.named_captures.each { |k, i|
                if v = matches[i]
                  routing_args[k] = v
                end
              }
              if condition.method == :path_info && !condition.anchored?
                env[Prefix::KEY] = m.to_s
              end
              true
            else
              false
            end
          }
            env[@set.parameters_key] = routing_args
            @app.call(env)
          else
            Const::EXPECTATION_FAILED_RESPONSE
          end
        end

        private
          def generate_keys
            @set.valid_conditions.inject({}) do |keys, method|
              if @conditions.has_key?(method)
                keys.merge!(@conditions[method].keys)
              end
              keys
            end
          end
      end
    end
  end
end
