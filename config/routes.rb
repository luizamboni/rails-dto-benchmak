Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  api_route_version = ENV.fetch("REGISTRATION_API_VERSION", "v1")

  namespace :api do
    if api_route_version == "v3"
      namespace :v3 do
        post "register" => "registrations#create"
        get "docs.json" => "docs#spec", defaults: { format: :json }
        get "docs" => "docs#show", format: false
      end
    elsif api_route_version == "v2"
      namespace :v2 do
        post "register" => "registrations#create"
        resources :users, only: [:index, :update]
      end
    else
      namespace :v1 do
        post "register" => "registrations#create"
        resources :users, only: [:index, :update]
      end
    end
  end

  # Defines the root path route ("/")
  # root "posts#index"
end
