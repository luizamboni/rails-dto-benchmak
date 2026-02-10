# typed: true

module Api
  module V3
    module Users
      class ListUsers
        def call
          User.select(:id, :email, :created_at, :updated_at).order(:id)
        end
      end
    end
  end
end
