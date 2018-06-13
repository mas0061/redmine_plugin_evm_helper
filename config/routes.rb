# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html
Rails.application.routes.draw do
    get '/projects/:project_id/issues.csvevm', :to => 'export_csv_with_evm#index'
end