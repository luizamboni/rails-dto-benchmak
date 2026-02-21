# typed: true

module Api
  module V2
    class RegistrationsController < Api::V2::ApplicationController
      extend T::Sig

      sig { void }
      def create
        dto = profiler_step("dto.parse") { RegistrationDto.from(request.request_parameters) }
        result = Registrations::CreateUser.new.call(dto)

        if result.user
          render json: { id: result.user.id, email: result.user.email }, status: :created
        else
          render json: { errors: result.errors }, status: :unprocessable_entity
        end
      rescue KeyError
        render json: { errors: [ "invalid payload" ] }, status: :bad_request
      end

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
