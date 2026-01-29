module Api
  module V1
    module Users
      class UpdateUser
        Result = Struct.new(:user, :errors, keyword_init: true)

        def initialize(user:, params:)
          @user = user
          @params = params
        end

        def call
          if @user.update(@params)
            Result.new(user: @user, errors: [])
          else
            Result.new(user: nil, errors: @user.errors.full_messages)
          end
        end
      end
    end
  end
end
