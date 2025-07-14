Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :v1 do
      post '/login', to: 'authentication#login'
      post '/logout', to: 'authentication#logout'
      post '/refresh_token', to: 'authentication#refresh_token'
      get '/profile', to: 'authentication#profile'
      put '/profile', to: 'authentication#update_profile'
      
      post '/register', to: 'registrations#create'
      
      resources :users do
        member do
          patch :activate
          patch :deactivate
          patch :invalidate_tokens
        end
      end
    end
  end

  # Defines the root path route ("/")
  # root "posts#index"
end
