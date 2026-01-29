module Api
  module V1
    module Registrations
      class CreateUser
        Result = Struct.new(:user, :errors, keyword_init: true)

        def initialize(params)
          @params = params
        end

        def call
          user = User.new(@params)

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
