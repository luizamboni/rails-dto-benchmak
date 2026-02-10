# typed: true

module Api
  module V3
    class UserResponse < Api::V3::StrictDTO
      field :id, Integer
      field :email, String
    end
  end
end
