# frozen_string_literal: true

Rails.application.routes.draw do
  resources 'pipeline_work_in_progress', only: :show

  get '/health' => 'rails/health#show', :as => :rails_health_check

  scope 'search', controller: :search do
    get '/', action: :new, as: :search
    post '/', action: :create, as: :perform_search
    get '/ongoing_plates', action: :ongoing_plates

    # TODO: do we need to add ongoing_tube_racks here?
    get '/ongoing_tubes', action: :ongoing_tubes
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

  resources :limber_qcables, controller: :tag_plates, only: [:show]

  resources :limber_plates, controller: :plates do
    resources :children, controller: :plate_creation
    resources :tubes, controller: :tube_creation
    resources :tube_racks, controller: :tube_rack_creation
    resources :qc_files
    resources :exports, only: :show
    resources :work_completions, only: :create, module: :plates
  end

  post '/fail_wells/:id', controller: :plates, action: 'fail_wells', as: :fail_wells
  post '/process_mark_under_represented_wells/:id',
       controller: :plates,
       action: 'process_mark_under_represented_wells',
       as: :process_mark_under_represented_wells

  resources :qc_files, only: :show

  resources :limber_tubes, controller: :tubes do
    resources :children, controller: :plate_creation
    resources :tubes, controller: :tube_creation
    resources :tube_racks, controller: :tube_rack_creation
    resources :qc_files, controller: :qc_files
    resources :tubes_exports, only: :show, module: :tubes
    resources :work_completions, only: :create, module: :tubes
  end

  resources :validate_paired_tubes, only: :index, module: :tubes

  resources :limber_tube_racks, controller: :tube_racks do
    resources :children, controller: :plate_creation
    resources :qc_files, controller: :qc_files
    resources :tube_racks_exports, only: :show, module: :tube_racks
    # TODO: need to add work completion code for tube racks
    # resources :tube_rack_work_completions, only: :create, module: :tube_racks
  end

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
