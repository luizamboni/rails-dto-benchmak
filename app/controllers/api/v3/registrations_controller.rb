# typed: true

module Api
  module V3
    class RegistrationsController < Api::V3::ApplicationController

      include Api::V3

      contract body: RegistrationRequest, responds: {
        created: RegistrationResponse,
        [:unprocessable_entity, :bad_request] => ErrorResponse
      }
      def create
        body_payload = resolve_body!
        result = Registrations::CreateUser.new.call(body_payload)

        if result.user
          return responds_for_status :created, { id: result.user.id, email: result.user.email }
        end

        responds_for_status :unprocessable_entity, { errors: result.errors }
      rescue StrictDTO::Error, KeyError => e
        Rails.logger.warn("v3 invalid payload: #{e.class}: #{e.message}")
        responds_for_status :bad_request, { errors: [ "invalid payload" ] }
      end
    end
  end
end
