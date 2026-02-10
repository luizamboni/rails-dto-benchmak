# typed: true

module Api
  module V3
    class RegistrationRequest < Api::V3::StrictDTO
      field :email, String
      field :password, String
      field :password_confirmation, String
    end
  end
end
