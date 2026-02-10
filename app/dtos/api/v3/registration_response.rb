# typed: true

module Api
  module V3
    class RegistrationResponse < Api::V3::StrictDTO
      field :id, Integer
      field :email, String
    end
  end
end
