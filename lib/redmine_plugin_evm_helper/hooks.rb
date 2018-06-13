module DisplayRole
  class Hooks < Redmine::Hook::ViewListener
    render_on :view_issues_index_bottom,
      :partial => 'hooks/redmine_plugin_evm_helper/view_issues_index_bottom'
  end
end
