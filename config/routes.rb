Rails.application.routes.draw do
  # system hook for add system-wide webhook
  post '/system', to: 'system#index'

  # oauth application
  get '/login', to: 'users#login'
  get '/oauth/callback', to: 'users#login'

  resources :issues

  resources :sprints

  resources :blogs

  # file upload
  post '/projects/:project_id/uploads', to: 'uploads#index'

  # project board
  get '/projects/:project_id/kanban', to: 'boards#index'

  # milestone board
  get '/milestones/:milestone_id/kanban', to: 'boards#index'

  # burndown chart
  get '/milestones/:milestone_id/burndown', to: 'burndown#index'

  # issues as root
  root 'issues#index'
end
