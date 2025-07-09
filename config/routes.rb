# frozen_string_literal: true

Rails.application.routes.draw do
  resources 'pipeline_work_in_progress', only: :show

  get '/health' => 'rails/health#show', :as => :rails_health_check

  scope 'search', controller: :search do
    get '/', action: :new, as: :search
    post '/', action: :create, as: :perform_search
    get '/ongoing_plates', action: :ongoing_plates
    get '/ongoing_tubes', action: :ongoing_tubes
    # TODO: do we need to add ongoing_tube_racks here?
    post '/qcables', action: :qcables, as: :qcables_search
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

  resources :qcables, controller: :tag_plates, only: [:show]

  resources :plates, controller: :plates do
    resources :child_plate_creation, controller: :plate_creation
    resources :child_tube_creation, controller: :tube_creation
    resources :child_tube_rack_creation, controller: :tube_rack_creation
    resources :qc_files
    resources :exports, only: :show
    resources :work_completions, only: :create, module: :plates
  end

  post '/fail_wells/:id', controller: :plates, action: 'fail_wells', as: :fail_wells

  resources :qc_files, only: :show

  resources :tubes, controller: :tubes do
    resources :child_plate_creation, controller: :plate_creation
    resources :child_tube_creation, controller: :tube_creation
    resources :child_tube_rack_creation, controller: :tube_rack_creation
    resources :qc_files, controller: :qc_files
    resources :tubes_exports, only: :show, module: :tubes
    resources :work_completions, only: :create, module: :tubes
  end

  resources :validate_paired_tubes, only: :index, module: :tubes

  resources :tube_racks, controller: :tube_racks do
    resources :children, controller: :plate_creation
    resources :qc_files, controller: :qc_files
    resources :tube_racks_exports, only: :show, module: :tube_racks
    # TODO: need to add work completion code for tube racks
    # resources :tube_rack_work_completions, only: :create, module: :tube_racks
  end

  # Add redirect to handle bookmarks and in-progress work.
  # These routes were changed as part of the SS API v2 migration.
  get '/limber_qcables(/*all)', to: redirect(path: '/qcables/%{all}')
  get '/limber_plates(/*all)', to: redirect(path: '/plates/%{all}')
  get '/limber_tubes(/*all)', to: redirect(path: '/tubes/%{all}')
  get '/limber_tube_racks(/*all)', to: redirect(path: '/tube_racks/%{all}')

  # limber_multiplexed_library_tube routes have been removed, and instead
  # mx tubes behave like standard tubes for the purposes of routing/url generation
  # Keeping this redirect here to handle bookmarks. The other routes weren't
  # actively being used.
  get '/limber_multiplexed_library_tube/:uuid', to: redirect('/limber_tubes/%<uuid>s')

  # Printing can do individual or multiple labels
  scope 'print', controller: :barcode_labels, via: :post do
    get 'individual', action: 'individual', as: :print_individual_label
    get 'multiple', action: 'multiple', as: :print_multiple_labels
  end

  resources :pipelines, only: :index

  resources :sequencescape_submissions

  root to: 'search#new'
end
