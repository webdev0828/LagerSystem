Jnlager::Application.routes.draw do

  devise_for :users

  get '/me' => 'me#edit', :as => :edit_me
  put '/me' => 'me#update', :as => :me

  # fix redirect for departments
  get '/departments/:id' => redirect('/departments/%{id}/customers')
  get '/departments' => redirect('/')



  resources :users do
    member do
      put 'toggle_customer/:customer_id', :action => :toggle_customer, :as => :toggle_customer
      put 'toggle_department/:department_id', :action => :toggle_department, :as => :toggle_department
      put 'lock'
      put 'unlock'
      put 'mail'
      put 'become'
    end
  end

  resources :departments, :only => [] do

    get 'order_history' => 'order_history#index', :as => :order_history

    get 'graphic(/:id_a(::shelf_a)(/:id_b(::shelf_b)))' => 'graphic#index',
        :constraints => { :id_a => /\d+/, :id_b => /\d+/, :shelf_a => /\d+/, :shelf_b => /\d+/ },
        :as => :graphic

    # this is supposed to be a member for graphic
    get 'graphic(/:id_a(::shelf_a)(/:id_b(::shelf_b)))/search' => 'graphic#search',
        :constraints => { :id_a => /\d+/, :id_b => /\d+/, :shelf_a => /\d+/, :shelf_b => /\d+/ },
        :as => :graphic_search


    post 'graphic/move' => 'graphic#move', :as => :graphic_move
    get  'graphic/info' => 'graphic#info', :as => :graphic_info
    # get  'graphic/search' => 'graphic#search', :as => :graphic_search

    get 'order_tray' => 'order_tray#index', :as => :order_tray

    resources :customers, :except => [:destroy] do
      post 'sort', :on => :collection

      

      resources :arrangements, :only => [:new,:create]
      resources :notes, :only => [:create,:update,:destroy]
      resources :orders do
        collection do
          get 'autofill'
          get 'search_pallets'
          get 'mark'
          get 'ready'
          put 'finish_marked'

          get 'all_order_pdfs'
          
        end
        member do
          put 'reserve'
          put 'cancel_reservation'
          put 'swap/:reservation_id/:pallet_id' => 'orders#swap', as: :swap

          put 'change'
          put 'submit'
          put 'reject'
          put 'carry_out'
          put 'mark_ready'
          put 'finish'

          put 'make_owner'

          get 'scrap_note' #, :defaults => { :format => 'pdf' }
          get 'pallet_note' #, :defaults => { :format => 'pdf' }
          get 'delivery_note' #, :defaults => { :format => 'pdf' }
          get 'exit_note' #, :defaults => { :format => 'pdf' }
        end
      end

      resources :pallets do
        resources :pallet_corrections
      end

      resources :arrivals do
        get 'autofill', :on => :collection
      end

      # resource :scan, :only => [ :show, :new, :edit, :create, :update ]

      resources :accounts, :as => :intervals, :except => [ :edit, :update ] do
        collection do
          get 'current'
          get 'test'
          get 'current_list'
          get 'current_list_weight'
        end
        member do
          get 'list'
          get 'list_weight'
          get 'summary'
        end
      end
    end

    resources :storages, :only => [:index] do
      post 'sort', :on => :collection
      get 'shelfs', :on => :collection
    end

    resources :organized_storages, :only => [:show, :edit, :update] do
      get 'print_shelf', :on => :member
    end
    resources :bulk_storages, :only => [:show, :edit, :update, :new, :create, :destroy]

    resources :customer_groups do
      get :pallets, on: :member
      resources :order_imports do
        get :approve, on: :member
      end
    end

  end

  root :to => 'departments#index'

  namespace :customer do
    root :to => 'home#index'
    resources :home, :only => [:index], :as => :customers, :path => '' do
      resources :pallets, :only => [:index, :show]
      resources :orders do
        collection do
          get 'autofill'
          get 'search_pallets'
          get 'finished'
        end
        member do
          put 'reserve'
          put 'cancel_reservation'

          put 'submit'
          put 'make_owner'

          get 'delivery_note' #, :defaults => { :format => 'pdf' }
          get 'exit_note' #, :defaults => { :format => 'pdf' }
        end
      end
    end
  end

  get '/docs/:page' => 'docs#show', as: :docs

end