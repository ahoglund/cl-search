class SearchController < ApplicationController
  def results
    query       = params.delete(:query)
    search      = CraigslistSearch.search(query, params)
    @results    = search.results
    @search_url = search.url
  end
end
