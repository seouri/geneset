Geneset::Application.routes.draw do
  resources :genes

  resources :articles
  match '/about' => "page#about", :as => "about"
  root :to => "page#home"
end
