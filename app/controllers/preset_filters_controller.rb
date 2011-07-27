class PresetFiltersController < ApplicationController
  unloadable
  layout 'base'
  before_filter :find_project, :authorize
  skip_before_filter :authorize, :only => [:show_issues]
  
  helper :queries
  helper :sort
  include SortHelper
  
  def index
    get_presets
  end  
  
  def by_presets
    prepare_query
    @content_title = PresetFilter.presets.index(params[:value].to_i).to_s.humanize.titleize     
    case params[:value].to_i
      when PresetFilter.presets[:recently_added]:         
        @query.add_filter('status_id', '=', ['1'])
        @query.add_filter('created_on', '>t-', ['14'])
        render_request('created_on', 'desc')
      when PresetFilter.presets[:recently_updated]: 
        @query.add_filter('updated_on', '>t-', ['14'])
        render_request('updated_on', 'desc')        
      when PresetFilter.presets[:recently_resolved]:
        @query.add_filter('status_id', '=', ['3'])
        @query.add_filter('updated_on', '>t-', ['14'])
        render_request('updated_on', 'desc')
      when PresetFilter.presets[:recently_closed]:
        @query.add_filter('status_id', '=', ['5'])
        @query.add_filter('updated_on', '>t-', ['14'])
        render_request('updated_on', 'desc')
      when PresetFilter.presets[:unassigned]: 
        @query.add_filter('assigned_to_id', '!', @project.users.collect{|u|u.id.to_s})
        render_request('updated_on', 'desc')
      when PresetFilter.presets[:assigned_to_me]: 
        @query.add_filter('assigned_to_id', '=', [User.current.id.to_s])
        render_request('updated_on', 'desc')
      when PresetFilter.presets[:all]:        
        @query.add_filter('status_id', '=', IssueStatus.find(:all).map{|c|c.id.to_s})
        render_request('updated_on', 'desc')
    end    
    
  end
  
  def by_status
    prepare_query
    @issue_status = IssueStatus.find(params[:value])
    @content_title = @issue_status.name
    @query.add_filter('status_id', '=', [@issue_status.id.to_s])
    render_request
  end
  
  def by_priority
    prepare_query
    @priority = Enumeration.find(params[:value])
    @content_title = @priority.name
    @query.add_filter('priority_id', '=', [@priority.id.to_s])    
    render_request
  end
  
  def by_assignee
    prepare_query
    @assignee = User.find(params[:value])
    @content_title = 'Assigned to ' + @assignee.name
    @query.add_filter('assigned_to_id', '=', [@assignee.id.to_s])    
    render_request
  end
  
  def by_version
    prepare_query
    if params[:value] != 'null'
      @version = Version.find(params[:value])
      @content_title = @version.name
      @query.add_filter('fixed_version_id', '=', [@version.id.to_s])
    else
      @content_title = 'Unversioned Issues'
      @query.add_filter('fixed_version_id', '!', @project.versions.map{|v|v.id.to_s})
      @query.add_filter('status_id', '=', IssueStatus.find(:all).map{|c|c.id.to_s})
    end
    render_request
  end
  
  def by_category
    prepare_query
    if params[:value] != 'null'
      @category = IssueCategory.find(params[:value])
      @content_title = @category.name
      @query.add_filter('category_id', '=', [@category.id.to_s])
    else
      @content_title = 'Uncategorized Issues'
      @query.add_filter('category_id', '!', @project.issue_categories.map{|c|c.id.to_s})
      @query.add_filter('status_id', '=', IssueStatus.find(:all).map{|c|c.id.to_s})
    end
    render_request
  end
  
  def show_issues
    prepare_query
    
    value = [params[:criteria_id]]
    if params[:criteria_id].to_i == 0
      if params[:criteria].eql?('assigned_to_id')
        value = @project.users.collect{|u| u.id.to_s }
      else
        value = IssueStatus.all.collect{|i| i.id.to_s if i.name =~ /resolve/i }.compact
      end
    end
    
    if !params[:criteria].eql?('status_id')
      if params[:criteria].eql?('assigned_to_id')
        new_and_open = IssueStatus.all.collect{|i| i.id.to_s if i.name.eql?("New") || i.name.eql?("Open") || i.name.eql?('Reopened') || !(i.name =~ /resolve/i).nil? }.compact
        @query.add_filter('status_id', '=', new_and_open)
      else
        @query.add_filter('status_id', '*', ['6'])
      end
    end
    
    @query.project = @project
    @query.add_filter(params[:criteria], params[:operator], value)
    session[:query] = {:project_id => @query.project_id, :filters => @query.filters}
    
    redirect_to :controller => 'issues', :action => 'index', :project_id => @project
  end
  
  private
    def find_project
      @project=Project.find(params[:id])
    end
    
    def get_presets
      @preset_filters = if User.current.is_a?(AnonymousUser)
          PresetFilter.presets.delete(:assigned_to_me)
          PresetFilter.presets.sort{|a,b| a.to_s <=> b.to_s} 
        else 
          PresetFilter.presets.sort{|a,b| a.to_s <=> b.to_s}
        end      
      @statuses = IssueStatus.find(:all)
      @priorities = Enumeration.priorities
      @assignees = @project.users
      @versions = @project.versions
      @categories = @project.issue_categories
    end
  
    def prepare_query      
      sort_init "#{Issue.table_name}.id", "desc"      
      sort_update ['created_at']
      @query = Query.new(:name => '_', :project => @project)
    end
    
    def render_request(sort_field = nil, order = nil)
      get_presets
      limit = per_page_option      
      @issue_count = Issue.count(:include => [:status, :project], :conditions => @query.statement)
      @issue_pages = Paginator.new self, @issue_count, limit, params['page']
      @issues = Issue.find(:all, :conditions => @query.statement, 
                           :include => [ :assigned_to, :status, :tracker, :project, :priority, :category, :fixed_version ],
                           :limit  =>  limit, :offset =>  @issue_pages.current.offset, 
                           :order => (sort_field && order && params[:sort_key].nil? ? "#{Issue.table_name}.#{sort_field} #{order}" : sort_clause))            
      if request.xhr?
        respond_to do |format|
          format.html { 
            render :template => 'preset_filters/index.rhtml', :layout => !request.xhr?
            #TODO render other formats e.g pdf, rss, etc.
          }          
        end
      end
    end
end
