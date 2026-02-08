# typed: true

module Api
  module V2
    class RegistrationsController < Api::V2::ApplicationController
      extend T::Sig

      sig { void }
      def create
        dto = RegistrationDto.from(request.request_parameters)
        result = Registrations::CreateUser.new.call(dto)

        if result.user
          render json: { id: result.user.id, email: result.user.email }, status: :created
        else
          render json: { errors: result.errors }, status: :unprocessable_entity
        end
      rescue KeyError
        render json: { errors: [ "invalid payload" ] }, status: :bad_request
      end
    end
  end
end
