# typed: true

module Api
  module V3
    class UsersController < Api::V3::ApplicationController
      include Api::V3

      contract responds: {
        ok: UserListResponse
      }
      def index
        users = Users::ListUsers.new.call
        responds_for_status :ok, {
          data: users.as_json,
          links: {
            self: request.original_url
          }
        }
      end

      contract path: UserPathParams, body: UserUpdateRequest, responds: {
        [:ok] => UserResponse,
        [:unprocessable_entity, :bad_request] => ErrorResponse
      }
      def update
        path = resolve_path!
        dto = resolve_body!
        user_id = path.id.to_i
        result = Users::UpdateUser.new(user_id: user_id, dto: dto).call

        if result.user
          return responds_for_status :ok, { id: result.user.id, email: result.user.email }
        end

        responds_for_status :unprocessable_entity, { errors: result.errors }
      rescue StrictDTO::Error, KeyError => e
        Rails.logger.warn("v3 invalid payload: #{e.class}: #{e.message}")
        responds_for_status :bad_request, { errors: [ "invalid payload" ] }
      end
    end
  end
end
