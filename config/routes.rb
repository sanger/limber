PulldownPipeline::Application.routes.draw do

  
  match '/plates/search' => 'plates#search', :as => :plate_search
  resources :plates
  
  resources :barcode_labels
  
  root :to => "plates#search"
  

end
