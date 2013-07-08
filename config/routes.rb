IlluminaBPipeline::Application.routes.draw do
  scope 'search', :controller => :search do
    match '/',                            :action => 'new',            :via => :get,  :as => :search
    match '/',                            :action => 'create_or_find', :via => :post, :as => :perform_search
    match '/ongoing_illumina_b_plates',   :action => :ongoing_plates
    match '/all_illumina_b_stock_plates', :action => :stock_plates
    match '/ongoing_illumina_a_plates',   :action => :ongoing_plates_illumina_a
    match '/all_illumina_a_stock_plates', :action => :stock_plates_illumina_a
    match '/retrieve_parent',             :action => :retrieve_parent
  end

  # Robots help us batch work up by function, rather than plate
  resources :robots, :controller => :robots do
    match '/:location',        :on => :member, :action => 'show'
    match '/:location/start',  :on => :member, :action => 'start'
    match '/:location/verify', :on => :member, :action => 'verify'
  end

  resources :illumina_b_plates, :controller => :plates do
    resources :children, :controller => :plate_creation
    resources :tubes,    :controller => :tube_creation
    resources :qc_files, :controller => :qc_files
  end
  post '/fail_wells/:id', :controller => :plates, :action => 'fail_wells', :as => :fail_wells

  namespace "admin" do
    resources :illumina_b_plates, :only => [:update, :edit], :as => :plates
  end

  resources :illumina_b_multiplexed_library_tube, :controller => :tubes do
    resources :qc_files, :controller => :qc_files
  end

  # This is a hack untill I get tube coercion working
  resources :illumina_b_tube, :controller => :tubes do
    resources :qc_files, :controller => :qc_files
  end


  # This is a hack untill I get tube coercion working
  resources :sequencescape_tubes, :controller => :tubes do
    resources :children, :controller => :tube_creation
    resources :qc_files, :controller => :qc_files
  end

  # Printing can do individual or multiple labels
  scope 'print', :controller => :barcode_labels, :via => :post do
    match 'individual', :action => 'individual', :as => :print_individual_label
    match 'multiple',   :action => 'multiple',   :as => :print_multiple_labels
  end

  root :to => "search#new"
end
