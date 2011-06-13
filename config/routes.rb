PulldownPipeline::Application.routes.draw do

  
  match '/plates/search' => 'plates#search', :as => :plate_search
  resources :plates do
    resources :children, :controller => :creation
  end
  
  resources :barcode_labels
  
  root :to => "plates#search"
  

end
