Geneset::Application.routes.draw do
  resources :articles
  resources :genes
  resources :subjects
  match '/about' => "page#about", :as => "about"
  root :to => "page#home"
end
