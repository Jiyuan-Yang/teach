Rails.application.routes.draw do
  # system hook for add system-wide webhook
  post '/system', to: 'system#index'

  # report interface for receive auto test result
  post '/report', to: 'report#index'

  # oauth application
  get '/login', to: 'users#login'
  get '/oauth/callback', to: 'users#login'

  resources :issues

  resources :sprints

  resources :blogs, only: %i[index new create]

  resources :projects, only: [], param: :project_id do
    member do
      # project board
      get 'kanban', to: 'boards#index'
      # file upload
      post 'uploads', to: 'uploads#index'
      resources :blogs, only: %i[show create update destroy] do
        member do
          get 'raw', to: 'blogs#show_raw'
        end

        resources :comments, only: %i[index create update destroy], constraints: ->(req) {req.format == :json}
      end
    end
  end

  resources :auto_test_projects, only: %i[index show]

  resources :milestones, only: [], param: :milestone_id do
    member do
      # milestone board
      get 'kanban', to: 'boards#index'
      # burndown chart
      get 'burndown', to: 'burndown#index'
    end
  end

  # issues as root
  root 'issues#index'
end
