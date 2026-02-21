# typed: true

module Api
  module V2
    module Registrations
      class CreateUser
        extend T::Sig
        Result = Struct.new(:user, :errors, keyword_init: true)

        sig { void }
        def initialize
        end

        sig { params(dto: Api::V2::RegistrationDto).returns(Result) }
        def call(dto)
          user = profiler_step("user.build") { User.new(dto.to_h) }

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
