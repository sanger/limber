# frozen_string_literal: true

Rails.application.routes.draw do
  scope 'search', controller: :search do
    get  '/',                 action: :new, as: :search
    post '/',                 action: :create, as: :perform_search
    get  '/ongoing_plates',   action: :ongoing_plates
    get  '/ongoing_tubes',    action: :ongoing_tubes
    post '/qcables',          action: :qcables, as: :qcables_search
    get  '/retrieve_parent',  action: :retrieve_parent
  end

  resource :sessions, only: %i[create delete] do
    # Also map logout to destroy
    get 'logout', action: :destroy
  end

  # Robots help us batch work up by function, rather than plate
  resources :robots, controller: :robots do
    member do
      post 'start'
      post 'verify'
    end
  end

  resources :print_jobs, only: [:create]

  resources :limber_qcables, controller: :tag_plates, only: [:show]

  resources :limber_plates, controller: :plates do
    resources :children, controller: :plate_creation
    resources :tubes,    controller: :tube_creation
    resources :qc_files
    resources :exports, only: :show
    resources :work_completions, only: :create, module: :plates
  end

  post '/fail_wells/:id', controller: :plates, action: 'fail_wells', as: :fail_wells

  resources :qc_files, only: :show

  resources :limber_tubes, controller: :tubes do
    resources :children, controller: :tube_creation
    resources :qc_files, controller: :qc_files
    resources :work_completions, only: :create, module: :tubes
  end

  # limber_multiplexed_library_tube routes have been removed, and instead
  # mx tubes behave like standard tubes for the purposes of routing/url generation
  # Keeping this redirect here to handle bookmarks. The other routes weren't
  # actively being used.
  get '/limber_multiplexed_library_tube/:uuid', to: redirect('/limber_tubes/%<uuid>s')

  # Printing can do individual or multiple labels
  scope 'print', controller: :barcode_labels, via: :post do
    match 'individual', action: 'individual', as: :print_individual_label
    match 'multiple',   action: 'multiple',   as: :print_multiple_labels
  end

  root to: 'search#new'
end
