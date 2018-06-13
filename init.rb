require 'redmine'
require_dependency 'redmine_plugin_evm_helper/hooks'

Redmine::Plugin.register :redmine_plugin_evm_helper do
  name 'EVM helper plugin'
  author 'mas0061'
  description 'This plugin adds EVM to exported CSV and displays EVM on each ticket.'
  version '1.0.0'
  url 'https://github.com/mas0061/redmine_plugin_evm_helper'
  author_url 'https://github.com/mas0061'

  # settings :default => {
  #   :role_text_color => 'red'
  # }, :partial => 'redmine_plugin_evm_helper/evm_helper_settings'
end
