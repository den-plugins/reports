require 'redmine'

RAILS_DEFAULT_LOGGER.info 'Starting Presets plugin for RedMine'

Redmine::Plugin.register :presets do
  name 'Preset plugin'
  author 'Exist'
  description 'This is a plugin for Redmine that generates preset filters automatically'
  version '0.1.0'
  
  project_module :preset_filters_module do
    #permission :index_preset, {:preset_filters => [:index]},       :public => true
    #permission :by_presets,   {:preset_filters => [:by_presets]},  :public => true
    #permission :by_status,    {:preset_filters => [:by_status]},   :public => true
    #permission :by_priority,  {:preset_filters => [:by_priority]}, :public => true
    #permission :by_assignee,  {:preset_filters => [:by_assignee]}, :public => true
    #permission :by_version,   {:preset_filters => [:by_version]},  :public => true
    #permission :by_category,  {:preset_filters => [:by_category]}, :public => true
    permission :enable_preset_filters, {:preset_filters => [:index, :by_presets, :by_status, :by_priority, :by_assignee, :by_version, :by_category]}
  end

  menu :project_menu, :preset_filters, {:controller => 'preset_filters', :action => 'index'}, :after => :repository
end
