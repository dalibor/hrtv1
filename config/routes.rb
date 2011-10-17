ActionController::Routing::Routes.draw do |map|
# ROOT
map.root :controller => 'static_page', :action => 'index'

  # LOGIN/LOGOUT
  map.resource  :user_session
  map.resource  :registration, :only => [:edit, :update]
  map.login     'login', :controller => 'user_sessions', :action => 'new'
  map.logout    'logout', :controller => 'user_sessions', :action => 'destroy'
  map.resources :password_resets

  # PROFILE
  map.resource :profile, :only => [:edit, :update, :disable_tips],
    :member => {:disable_tips => :put}

  # STATIC PAGES
  map.about_page 'about', :controller => 'static_page',
    :action => 'about'

  map.resources :comments

  # ALL USERS
  map.dashboard 'dashboard', :controller => 'dashboard', :action => :index
  map.set_request 'set_request/:id', :controller => 'users', :action => :set_request
  map.set_latest_request 'set_latest_request', :controller => 'users', :action => :set_latest_request

  # ADMIN
  map.namespace :admin do |admin|
    admin.resources :requests
    admin.resources :responses,
      :collection => {:empty => :get, :in_progress => :get, :submitted => :get}
    admin.resources :organizations,
      :collection => {:duplicate => :get, :remove_duplicate  => :put,
                      :download_template => :get, :create_from_file => :post}
    admin.resources :reports,
      :member => { :generate => :get },
      :collection => { :mark_implementer_splits => :put}
    admin.resources :currencies, :only => [:index, :new, :create, :update, :destroy]
    admin.resources :users, :except => [:show],
      :collection => {:create_from_file => :post, :download_template => :get}
    admin.resources :codes,
      :collection => {:create_from_file => :post, :download_template => :get}
    admin.resources :comments
  end

  # REPORTER USER: DATA ENTRY
  map.resources :responses,
    :except => [:index, :new, :create, :edit, :update, :destroy],  # yeah, ridicuI know.
    :member => {:review => :get, :submit => :put,
                :send_data_response => :put, :approve_all_budgets => :put,
                :reject => :put, :accept => :put} do |response|
    response.resources :projects, :except => [:show],
      :collection => {:download_template => :get,
                      :export_workplan => :get,
                      :export => :get,
                      :import => :post,
                      :import_and_save => :post}
    response.resources :activities, :except => [:index, :show],
      :member => {:sysadmin_approve => :put, :activity_manager_approve => :put},
      :collection => {:template => :get,
                      :export => :get}
    response.resources :other_costs, :except => [:index, :show],
      :collection => {:create_from_file => :post, :download_template => :get}
    response.resources :districts, :only => [:index, :show] do |district|
      district.resources :activities, :only => [:index, :show],
        :controller => "districts/activities"
      district.resources :organizations, :only => [:index, :show],
        :controller => "districts/organizations"
    end

    response.resources :reports, :only => [:index, :show]
  end

  map.resources :activities
  map.resources :organizations, :only => [:edit, :update],
    :collection => { :export => :get }

  # REPORTS
  map.charts 'charts/:action', :controller => 'charts' # TODO: convert to resource

  map.namespace :reports do |reports|
    reports.resources :districts, :only => [:index, :show],
      :member => {:classifications => :get} do |districts|
      districts.resources :activities, :only => [:index, :show],
        :controller => "districts/activities"
      districts.resources :organizations, :only => [:index, :show],
        :controller => "districts/organizations"
    end
    reports.resource :country,
      :member => {:classifications => :get} do |country|
      country.resources :activities, :only => [:index, :show],
        :controller => "countries/activities"
      country.resources :organizations, :only => [:index, :show],
        :controller => "countries/organizations"
    end
  end
end
