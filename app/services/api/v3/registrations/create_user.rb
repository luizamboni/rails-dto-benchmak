# typed: true

module Api
  module V3
    module Registrations
      class CreateUser
        Result = Struct.new(:user, :errors, keyword_init: true)

        def call(dto)
          user = User.new(dto.to_h)

          if user.save
            Result.new(user: user, errors: [])
          else
            Result.new(user: nil, errors: user.errors.full_messages)
          end
        end
      end
    end
  end
end
