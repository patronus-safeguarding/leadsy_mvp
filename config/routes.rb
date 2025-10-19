Rails.application.routes.draw do
  get 'access_grants/show'
  get 'access_grants/index'
  get 'dashboard/index'
  devise_for :users
  
  # Root route
  root "dashboard#index"
  
  # Agency authenticated routes
  authenticate :user do
    # Dashboard
    get "dashboard", to: "dashboard#index"
    
    # Access Templates
    resources :access_templates do
      member do
        patch :duplicate
      end
    end
    
    # Access Requests
    resources :access_requests do
      member do
        patch :resend
        patch :cancel
      end
      collection do
        get :export
      end
    end
    
    # Access Grants
    resources :access_grants, only: [:show, :index] do
      member do
        patch :revoke
        patch :refresh
      end
    end
    
    # User Invitations
    resources :user_invitations, only: [:show] do
      member do
        get :business_accounts
        post :invite_user
      end
    end
    
    # API Testing
    get 'api_test/meta/:grant_id', to: 'api_test#test_meta', as: 'test_meta_api'
    get 'api_test/google/:grant_id', to: 'api_test#test_google', as: 'test_google_api'
    
    # Clients
    resources :clients
  end
  
  # Public client routes (no authentication required)
  namespace :links do
    resources :access_requests, only: [:show], param: :token do
      member do
        get :approve
      end
    end
  end
  
  # Provider OAuth routes (no authentication required)
  namespace :providers do
    resources :oauth, only: [] do
      collection do
        get :meta, to: "oauth#meta_redirect"
        get :google, to: "oauth#google_redirect"
        get :meta_callback, to: "oauth#meta_callback"
        get :google_callback, to: "oauth#google_callback"
      end
    end
  end
  
  # Webhooks (no authentication required)
  namespace :webhooks do
    resources :providers, only: [] do
      collection do
        post :meta
        post :google
      end
    end
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check
end
