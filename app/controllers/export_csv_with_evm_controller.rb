class ExportCsvWithEvmController < ApplicationController
  default_search_scope :issues
  before_action :find_issues
  helper :queries
  include QueriesHelper

  def index
    retrieve_query

    if @query.valid?
      @issues = @query.issues

      puts @issues
      # send_data(query_to_csv(@issues, @query, params[:csv]), :type => 'text/csv; header=present', :filename => 'issues_w_evm.csv')
    end
  end
end
