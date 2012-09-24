SeriesApi::Application.routes.draw do
  match "series/search/:query" => "series#search"
  match "series/:id(/:season(/:episode))" => "series#show"
  root to: "series#index"
end
