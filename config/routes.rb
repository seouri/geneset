Geneset::Application.routes.draw do
  resources :articles
  resources :genes
  resources :subjects
  match 'meshcomplete-update' => 'genes#top'
  match '/about' => "page#about", :as => "about"
  root :to => "page#home"
end
