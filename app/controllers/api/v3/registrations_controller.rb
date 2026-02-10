# typed: true

module Api
  module V3
    class RegistrationsController < Api::V3::ApplicationController
      class UserRegistrationInput < Api::V3::StrictDTO
        field :email, String
        field :password, String
        field :password_confirmation, String
      end

      class UserRegistrationOutput < Api::V3::StrictDTO
        field :id, Integer
        field :email, String
      end

      class RegistrationErrors < Api::V3::StrictDTO
        field :errors, Array
      end

      contract body: UserRegistrationInput, responds: {
        created: UserRegistrationOutput,
        unprocessable_entity: RegistrationErrors,
        bad_request: RegistrationErrors
      }
      def create
        body_payload = resolve_body!
        result = Api::V3::Registrations::CreateUser.new.call(body_payload)

        if result.user
          return responds_for_status :created, { id: result.user.id, email: result.user.email }
        end

        responds_for_status :unprocessable_entity, { errors: result.errors }
      rescue Api::V3::StrictDTO::Error, KeyError => e
        Rails.logger.warn("v3 invalid payload: #{e.class}: #{e.message}")
        responds_for_status :bad_request, { errors: [ "invalid payload" ] }
      end
    end
  end
end
