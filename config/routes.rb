#This file is part of Illumina-B Pipeline is distributed under the terms of GNU General Public License version 3 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2011,2012,2013,2014,2015 Genome Research Ltd.
Rails.application.routes.draw do
  scope 'search', :controller => :search do
    get  '/',                 action: :new,                       as: :search
    post '/',                 action: :create_or_find,            as: :perform_search
    get  '/all_stock_plates', action: :stock_plates_illumina_a
    get  '/ongoing_plates',   action: :ongoing_plates_illumina_a
    post '/qcables',          action: :qcables,                   as: :qcables_search
    get  '/retrieve_parent',  action: :retrieve_parent
    get '/my_plates',        action: :my_plates
  end

  resource :sessions, only: [:create, :delete] do
    # Also map logout to destroy
    get 'logout', action: :destroy
  end

  # Robots help us batch work up by function, rather than plate
  resources :robots, :controller => :robots do
    member do
      post 'start'
      post 'verify'
    end
  end

  resources :limber_qcables, :controller => :tag_plates, :only=>[:show]

  resources :limber_plates, :controller => :plates do
    resources :children, :controller => :plate_creation
    resources :tubes,    :controller => :tube_creation
    resources :qc_files, :controller => :qc_files
  end
  post '/fail_wells/:id', :controller => :plates, :action => 'fail_wells', :as => :fail_wells

  resources :limber_multiplexed_library_tube, :controller => :tubes do
    resources :qc_files, :controller => :qc_files
  end

  # This is a hack until I get tube coercion working
  resources :limber_tube, :controller => :tubes do
    resources :qc_files, :controller => :qc_files
  end


  # This is a hack until I get tube coercion working
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
