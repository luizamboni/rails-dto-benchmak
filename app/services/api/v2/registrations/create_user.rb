# typed: true

module Api
  module V2
    module Registrations
      class CreateUser
        extend T::Sig
        Result = Struct.new(:user, :errors, keyword_init: true)

        sig { void }
        def initialize
        end

        sig { params(dto: Api::V2::RegistrationDto).returns(Result) }
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
