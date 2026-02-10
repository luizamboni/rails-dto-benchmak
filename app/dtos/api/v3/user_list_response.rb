# typed: true

module Api
  module V3
    class UserListResponse < Api::V3::StrictDTO
      field :data, Array
      field :links, Hash
    end
  end
end
