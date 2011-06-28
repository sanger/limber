PulldownPipeline::Application.routes.draw do
  match '/search' => 'search#new', :as => :search

  resources :pulldown_plates, :controller => :plates do
    resources :children, :controller => :plate_creation
    resources :tubes,    :controller => :tube_creation

  end
  post '/fail_wells/:id', :controller => :plates, :action => 'fail_wells', :as => :fail_wells

  resources :pulldown_multiplexed_library_tubes, :controller => :tubes do

  end

  # Printing can do individual or multiple labels
  scope 'print', :controller => :barcode_labels, :via => :post do
    match 'individual', :action => 'individual', :as => :print_individual_label
    match 'multiple',   :action => 'multiple',   :as => :print_multiple_labels
  end

  root :to => "search#new"
end
