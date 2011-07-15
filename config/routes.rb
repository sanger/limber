PulldownPipeline::Application.routes.draw do
  scope 'search', :controller => :search do
    match '/',                       :action => 'new',    :via => :get,  :as => :search
    match '/',                       :action => 'create', :via => :post, :as => :perform_search
    match '/all_outstanding_plates', :action => :all_outstanding_plates
  end

  resources :pulldown_plates, :controller => :plates do
    resources :children, :controller => :plate_creation
    resources :tubes,    :controller => :tube_creation
  end
  post '/fail_wells/:id', :controller => :plates, :action => 'fail_wells', :as => :fail_wells

  namespace "admin" do
    resources :pulldown_plates, :only => [:update, :edit], :as => :plates
  end

  resources :pulldown_multiplexed_library_tubes, :controller => :tubes do

  end

  # Printing can do individual or multiple labels
  scope 'print', :controller => :barcode_labels, :via => :post do
    match 'individual', :action => 'individual', :as => :print_individual_label
    match 'multiple',   :action => 'multiple',   :as => :print_multiple_labels
  end

  root :to => "search#new"
end
