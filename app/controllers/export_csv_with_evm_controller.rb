# ToDo 全プロジェクトのチケット一覧で動かない
class ExportCsvWithEvmController < ApplicationController
  require 'csv'

  rescue_from Query::StatementInvalid, :with => :query_statement_invalid

  helper :journals
  helper :issues
  helper :projects
  helper :queries
  include QueriesHelper

  def index
    @project = Project.find(params[:project_id])
    retrieve_query

    if @query.valid?
      @issues = @query.issues
      columns = @query.columns

      if User.current.allowed_to?(:view_time_entries, @project)
        Issue.load_visible_spent_hours(@issues)
        Issue.load_visible_total_spent_hours(@issues)
        csv_data = query_to_csv_w_evm(@issues, @query, params[:csv])
      else
        # If the user is not permitted to view the time entry, use the default CSV output.
        csv_data = query_to_csv(@issues, @query, params[:csv])
      end

      # for debug
      # csv_data.each_line do |line|
      #   puts line.force_encoding(Encoding::Shift_JIS)
      # end

      send_data(csv_data, :type => 'text/csv; header=present', :filename => 'issues_w_evm.csv')
    end
  end

  def query_to_csv_w_evm(items, query, options={})
    columns = query.columns

    Redmine::Export::CSV.generate do |csv|
      # add EVM header to default method
      csv << (columns.map {|c| c.caption.to_s} + ['PV', 'EV', 'AC', 'BAC'])
      # add EVM value to default method
      items.each do |item|
        csv << (columns.map {|c| csv_content(c, item)} + calc_evm_to_array(item))
      end
    end
  end

  def calc_evm_to_array(issue)
    bac = issue.total_estimated_hours
    ac = issue.total_spent_hours

    if issue.closed? then
      ev = bac
    else
      ev = (bac * (issue.done_ratio * 0.01)).round(2)
    end

    term = issue.due_date - issue.start_date
    now_diff = Date.today - issue.start_date

    if now_diff > term then
      pv = bac
    elsif now_diff < 0 then
      pv = 0
    else
      pv = ((bac / term) * now_diff).round(2)
    end

    [pv, ev, ac, bac]
  end
end
