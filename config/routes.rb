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
    admin.resources :reports, :member => {:generate => :get}
    admin.resources :currencies, :only => [:index, :update, :destroy]
    admin.resources :users,
      :collection => {:create_from_file => :post, :download_template => :get}
    admin.resources :codes,
      :collection => {:create_from_file => :post, :download_template => :get}
    admin.resources :comments
  end

  # POLICY MAKER
  map.namespace :policy_maker do |policy_maker|
    policy_maker.resources :responses, :only => [:show, :index]
  end

  # REPORTER USER: DATA ENTRY
  map.resources :responses,
    :except => [:index, :new, :create, :edit, :update, :destroy],  # yeah, ridicuI know.
    :member => {:review => :get, :submit => :get, :send_data_response => :put} do |response|
    response.resources :projects,
      :collection => {:create_from_file => :post,
                      :download_template => :get,
                      :bulk_edit => :get,
                      :export => :get,
                      :bulk_update => :put}
    response.resources :activities, :except => [:index, :show],
      :member => {:sysadmin_approve => :put, :activity_manager_approve => :put, :classifications => :get},
      :collection => {:bulk_create => :post,
                      :template => :get,
                      :export => :get,
                      :project_sub_form => :get}
    response.resources :other_costs,
      :collection => {:create_from_file => :post, :download_template => :get}
    response.resources :districts, :only => [:index, :show] do |district|
      district.resources :activities, :only => [:index, :show],
        :controller => "districts/activities"
      district.resources :organizations, :only => [:index, :show],
        :controller => "districts/organizations"
    end
  end

  map.resources :activities do |activity|
    activity.resource :code_assignments,
      :only => [:show, :update],
      :member => {:copy_spend_to_budget => :put,
      :derive_classifications_from_sub_implementers => :put},
      :collection => {:bulk_create => :put, :download_template => :get}
    activity.resources :sub_activities,
      :only => [:index, :create],
      :collection => {:template => :get, :bulk_create => :post}
  end

  map.resources :organizations, :only => [:edit, :update],
    :collection => { :export => :get }

  # REPORTER USER
  map.namespace :reporter do |reporter|
    reporter.set_latest_response 'set_latest_response', :controller => 'responses', :action => :set_latest
    reporter.resources :reports, :only => [:index, :show]
  end

  # REPORTS
  map.charts 'charts/:action', :controller => 'charts' # TODO: convert to resource

  map.namespace :reports do |reports|
    reports.resources :districts, :only => [:index, :show] do |districts|
      districts.resources :activities, :only => [:index, :show],
        :controller => "districts/activities"
      districts.resources :organizations, :only => [:index, :show],
        :controller => "districts/organizations"
    end
    reports.resource :country do |country|
      country.resources :activities, :only => [:index, :show],
        :controller => "countries/activities"
      country.resources :organizations, :only => [:index, :show],
        :controller => "countries/organizations"
    end
  end
end
