# typed: true

module Api
  module V2
    module Users
      class ListUsers
        extend T::Sig

        sig { returns(ActiveRecord::Relation) }
        def call
          User.select(:id, :email, :created_at, :updated_at).order(:id)
        end
      end
    end
  end
end
