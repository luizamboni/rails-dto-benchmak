module Api
  module V1
    module Registrations
      class CreateUser
        Result = Struct.new(:user, :errors, keyword_init: true)

        def initialize(params)
          @params = params
        end

        def call
          user = profiler_step("user.build") { User.new(@params) }

          if profiler_step("user.save") { user.save }
            Result.new(user: user, errors: [])
          else
            errors = profiler_step("user.errors") { user.errors.full_messages }
            Result.new(user: nil, errors: errors)
          end
        end

        private

        def profiler_step(name, &block)
          if defined?(Rack::MiniProfiler)
            Rack::MiniProfiler.step(name, &block)
          else
            block.call
          end
        end
      end
    end
  end
end
