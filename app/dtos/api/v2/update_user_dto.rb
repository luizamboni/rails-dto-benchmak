# typed: true

module Api
  module V2
    class UpdateUserDto
      extend T::Sig

      sig { params(params: T::Hash[String, T.untyped]).returns(Api::V2::UpdateUserDto) }
      def self.from(params)
        user = params.fetch("user")

        new(
          email: user["email"],
          password: user["password"],
          password_confirmation: user["password_confirmation"]
        )
      end

      sig do
        params(
          email: T.nilable(String),
          password: T.nilable(String),
          password_confirmation: T.nilable(String)
        ).void
      end
      def initialize(email:, password:, password_confirmation:)
        @email = email
        @password = password
        @password_confirmation = password_confirmation
      end

      sig { returns(T::Hash[Symbol, String]) }
      def to_h
        data = {}
        data[:email] = @email if @email
        if @password && !@password.empty?
          data[:password] = @password
          data[:password_confirmation] = @password_confirmation
        end
        data
      end
    end
  end
end
