# typed: true

module Api
  module V2
    class RegistrationDto
      extend T::Sig

      sig { params(params: T::Hash[String, T.untyped]).returns(Api::V2::RegistrationDto) }
      def self.from(params)
        user = params.fetch("user")

        new(
          email: user.fetch("email"),
          password: user.fetch("password"),
          password_confirmation: user.fetch("password_confirmation")
        )
      end

      sig do
        params(
          email: String,
          password: String,
          password_confirmation: String
        ).void
      end
      def initialize(email:, password:, password_confirmation:)
        @email = email
        @password = password
        @password_confirmation = password_confirmation
      end

      sig { returns(T::Hash[Symbol, String]) }
      def to_h
        {
          email: @email,
          password: @password,
          password_confirmation: @password_confirmation
        }
      end
    end
  end
end
