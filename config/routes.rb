Rails.application.routes.draw do
  root "search#new"
  get 'search/new'
  get 'search/results'
end
