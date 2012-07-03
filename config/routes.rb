IlluminaBPipeline::Application.routes.draw do
  scope 'search', :controller => :search do
    match '/',                       :action => 'new',    :via => :get,  :as => :search
    match '/',                       :action => 'create_or_find', :via => :post, :as => :perform_search
    match '/ongoing_plates', :action => :ongoing_plates
    match '/all_stock_plates', :action => :stock_plates
  end

  resources :illumina_b_plates, :controller => :plates do
    resources :children, :controller => :plate_creation
    resources :tubes,    :controller => :tube_creation
  end
  post '/fail_wells/:id', :controller => :plates, :action => 'fail_wells', :as => :fail_wells

  namespace "admin" do
    resources :illumina_b_plates, :only => [:update, :edit], :as => :plates
  end

  resources :illumina_b_multiplexed_library_tubes, :controller => :tubes do

  end

  # Printing can do individual or multiple labels
  scope 'print', :controller => :barcode_labels, :via => :post do
    match 'individual', :action => 'individual', :as => :print_individual_label
    match 'multiple',   :action => 'multiple',   :as => :print_multiple_labels
  end

  root :to => "search#new"
end
