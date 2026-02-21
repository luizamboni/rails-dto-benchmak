module Api
  module V1
    class RegistrationsController < Api::V1::ApplicationController
      def create
        params_payload = profiler_step("params.permit") { user_params }
        result = Api::V1::Registrations::CreateUser.new(params_payload).call

        if result.user
          render json: { id: result.user.id, email: result.user.email }, status: :created
        else
          render json: { errors: result.errors }, status: :unprocessable_entity
        end
      end

      private

      def user_params
        params.require(:user).permit(:email, :password, :password_confirmation)
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
