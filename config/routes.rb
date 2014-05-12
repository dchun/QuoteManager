class SubdomainPresent
  def self.matches?(request)
    request.subdomain.present?
  end
end

class SubdomainBlank
  def self.matches?(request)
    request.subdomain.blank?
  end
end

QuoteManager::Application.routes.draw do
  
  constraints(SubdomainPresent) do
    root 'dashboard#index', as: :subdomain_root
    resources :forms
    resources :requests
    resources :quotes
    devise_for :users
  end
  
  constraints(SubdomainBlank) do
    root 'welcome#index'
    post 'login' => 'accounts#login'
    resources :accounts, only: [:new, :create]
  end
end
