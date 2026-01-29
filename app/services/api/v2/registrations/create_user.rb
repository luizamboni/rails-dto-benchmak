# typed: true

module Api
  module V2
    module Registrations
      class CreateUser
        extend T::Sig
        Result = Struct.new(:user, :errors, keyword_init: true)

        sig { params(params: T::Hash[Symbol, T.untyped]).void }
        def initialize(params)
          @params = params
        end

        sig { returns(Result) }
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
