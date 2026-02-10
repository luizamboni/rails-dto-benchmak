# typed: true

module Api
  module V3
    module Users
      class UpdateUser
        Result = Struct.new(:user, :errors, keyword_init: true)

        def initialize(user_id:, dto:)
          @user_id = user_id
          @dto = dto
        end

        def call
          user = User.find(@user_id)
          if user.update(@dto.to_h)
            Result.new(user: user, errors: [])
          else
            Result.new(user: nil, errors: user.errors.full_messages)
          end
        end
      end
    end
  end
end
