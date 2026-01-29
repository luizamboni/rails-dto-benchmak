module Api
  module V1
    class RegistrationsController < Api::V1::ApplicationController
      def create
        result = Api::V1::Registrations::CreateUser.new(user_params).call

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
    end
  end
end
