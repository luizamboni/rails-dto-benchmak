# typed: true

module Api
  module V3
    class UserUpdateRequest < Api::V3::StrictDTO
      field :email, String, required: false
      field :password, String, required: false
      field :password_confirmation, String, required: false

      def to_h
        data = {}
        data[:email] = email if email
        if password && !password.empty?
          data[:password] = password
          data[:password_confirmation] = password_confirmation
        end
        data
      end
    end
  end
end
