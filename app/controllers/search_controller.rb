class SearchController < ApplicationController
  def results
    query       = params.delete(:query)
    search      = CraigslistSearch.search(query, params)
    @results    = search.results
  end
end
