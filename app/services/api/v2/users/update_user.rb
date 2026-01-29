# typed: true

module Api
  module V2
    module Users
      class UpdateUser
        extend T::Sig
        Result = Struct.new(:user, :errors, keyword_init: true)

        sig { params(user_id: Integer, dto: Api::V2::UpdateUserDto).void }
        def initialize(user_id:, dto:)
          @user_id = user_id
          @dto = dto
        end

        sig { returns(Result) }
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
