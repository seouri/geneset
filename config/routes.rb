Geneset::Application.routes.draw do
  resources :articles

  root :to => "page#home"
end
