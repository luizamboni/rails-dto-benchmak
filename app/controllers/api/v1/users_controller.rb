module Api
  module V1
    class UsersController < Api::V1::ApplicationController
      def index
        users = Api::V1::Users::ListUsers.new.call
        render json: users
      end

      def update
        user = User.find(params[:id])
        result = Api::V1::Users::UpdateUser.new(user: user, params: update_params).call

        if result.user
          render json: { id: result.user.id, email: result.user.email }, status: :ok
        else
          render json: { errors: result.errors }, status: :unprocessable_entity
        end
      end

      private

      def update_params
        permitted = params.require(:user).permit(:email, :password, :password_confirmation)

        if permitted[:password].blank?
          permitted.delete(:password)
          permitted.delete(:password_confirmation)
        end

        permitted
      end
    end
  end
end
