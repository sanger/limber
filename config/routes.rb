PulldownPipeline::Application.routes.draw do

  
  match '/search' => 'search#new', :as => :search
  
  resources :plates do
    resources :children, :controller => :creation
  end
  
  resources :barcode_labels
  
  root :to => "search#new"
  

end
