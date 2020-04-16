class SearchController < ApplicationController
  def results
    query       = params.delete(:query)
    @debug      = params.delete(:debug)
    search      = CraigslistSearch.search(query, params)
    @results    = search.results
  end
end
