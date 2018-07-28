# ToDo 全プロジェクトのチケット一覧で動かない
class ExportCsvWithEvmController < ApplicationController
  require 'csv'

  rescue_from Query::StatementInvalid, :with => :query_statement_invalid

  helper :journals
  helper :issues
  helper :projects
  helper :queries
  include QueriesHelper
  include Redmine::I18n

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
      csv << (columns.map {|c| c.caption.to_s} + ['開始日（実績）', '終了日（実績）', 'PV', 'EV', 'AC', 'BAC'])
      # add EVM value to default method
      items.each do |item|
        # p item
        closed_date = item.closed_on.nil? ? nil : format_date(item.closed_on.to_date)
        csv << (columns.map {|c| csv_content(c, item)} + [search_journals(item), closed_date] + calc_evm_to_array(item))
      end
    end
  end

  def calc_evm_to_array(issue)
    bac = issue.total_estimated_hours || 0
    ac = issue.total_spent_hours || 0
    done_ratio = issue.done_ratio || 0
    ev = issue.closed? ? bac : (bac * (done_ratio * 0.01)).round(2)

    if !issue.start_date.nil? && !issue.due_date.nil? then
      term = issue.due_date - issue.start_date
      now_diff = Date.today - issue.start_date
  
      if now_diff > term then
        pv = bac
      elsif now_diff < 0 then
        pv = 0
      else
        pv = ((bac / term) * now_diff).round(2)
      end
    else
      pv = 0
    end

    [pv, ev, ac, bac]
  end

  def search_journals(issue)
    journals = issue.visible_journals_with_index
    actual_start_date = nil

    journals.each do |journal|
      # p journal
      # p journal.visible_details
      actual_start_date = journal.visible_details.find { |detail| detail.prop_key == "status_id" && detail.value == "2" && detail.old_value == "1"}
      if !actual_start_date.nil? then
        actual_start_date = format_date(journal.created_on.to_date)
        break
      end
    end
    # puts actual_start_date

    actual_start_date
  end
end
