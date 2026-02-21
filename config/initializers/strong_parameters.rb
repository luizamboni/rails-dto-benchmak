registration_api_version = ENV.fetch("REGISTRATION_API_VERSION", "v1")

if %w[v2 v3].include?(registration_api_version)
  ActionController::Parameters.permit_all_parameters = true
else
  ActionController::Parameters.permit_all_parameters = false
end
