# typed: true

module Api
  module V3
    class ErrorResponse < Api::V3::StrictDTO
      field :errors, Array
    end
  end
end
