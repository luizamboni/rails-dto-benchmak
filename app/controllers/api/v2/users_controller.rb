# typed: true

module Api
  module V2
    class UsersController < Api::V2::ApplicationController
      extend T::Sig

      sig { void }
      def index
        users = Api::V2::Users::ListUsers.new.call
        render json: users
      end

      sig { void }
      def update
        dto = Api::V2::UpdateUserDto.from(request.request_parameters)
        user_id = request.path_parameters.fetch("id").to_i
        result = Api::V2::Users::UpdateUser.new(user_id: user_id, dto: dto).call

        if result.user
          render json: { id: result.user.id, email: result.user.email }, status: :ok
        else
          render json: { errors: result.errors }, status: :unprocessable_entity
        end
      rescue KeyError
        render json: { errors: [ "invalid payload" ] }, status: :bad_request
      end
    end
  end
end
