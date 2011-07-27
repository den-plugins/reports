module PresetFiltersHelper
    
  def render_progress_bar_by(project, criteria, value)
    h = Hash.new {|k,v| k[v] = [0, 0]}
    begin      
      total_issues = Issue.count(:conditions => ["#{Issue.table_name}.project_id = ?", project])      
#      total_issues = Issue.count(:conditions => ["project_id in (select project_id from projects where project_id=? union all select project_id from projects where parent_id=?)", project, project])
      case criteria
        when 'status':
          Issue.count(:group => criteria, :include => :status,
            :conditions => ["#{Issue.table_name}.project_id = ? AND #{IssueStatus.table_name}.id = ?", project.id, value]).each {|c,s| h[c][1] = s} 
        when 'priority':
          Issue.count(:group => criteria, :include => [:priority, :status],
            :conditions => ["#{Issue.table_name}.project_id = ? AND #{Issue.table_name}.priority_id = ? 
                             AND #{IssueStatus.table_name}.is_closed = ?", project.id, value, false]).each {|c,s| h[c][1] = s} 
        when 'assigned_to':
          Issue.count(:group => criteria, :include => [:assigned_to, :status],
            :conditions => ["#{Issue.table_name}.project_id = ? AND #{Issue.table_name}.assigned_to_id = ? 
                             AND #{IssueStatus.table_name}.is_closed = ?", project.id, value, false]).each {|c,s| h[c][1] = s} 
        when 'fixed_version':
          if value == -1
            if project.versions.empty?
              s = Issue.count(:conditions => ["project_id = ? and fixed_version_id is null", project.id])
              c = Array.new
              c[1] = s
              h.store(nil, c)
            else
              Issue.count(:group => criteria, :conditions => ["#{Issue.table_name}.project_id = ?", project.id]).each {|c,s| h[c][1] = s}
            end
          else
            Issue.count(:group => criteria, :include => [:fixed_version, :status],
              :conditions => ["#{Issue.table_name}.project_id = ? AND #{Issue.table_name}.fixed_version_id = ? 
                               AND #{IssueStatus.table_name}.is_closed = ?", project.id, value, false]).each {|c,s| h[c][1] = s} 
          end
        when 'category':
          if value == -1
            Issue.count(:group => 'category', :conditions => ["#{Issue.table_name}.project_id = ?", project.id]).each {|c,s| h[c][1] = s} 
          else
            Issue.count(:group => criteria, :include => [:category, :status],
              :conditions => ["#{Issue.table_name}.project_id = ? AND #{Issue.table_name}.category_id = ? 
                             AND #{IssueStatus.table_name}.is_closed = ?", project.id, value, false]).each {|c,s| h[c][1] = s} 
          end          
      end      
    rescue ActiveRecord::RecordNotFound
      # When grouping by an association, Rails throws this exception if there's no result (bug)
    end
    counts = value == -1 ? h.keys.collect {|k| {:group => k, :total => total_issues, :open => h[k][1]} if k.nil? }.compact : h.keys.compact.sort.collect {|k| {:group => k, :total => total_issues, :open => h[k][1]}}    
    max = counts.collect {|c| c[:total]}.max
    
    render :partial => 'bar', :locals => {:project_id => project.id, :criteria => criteria, :counts => counts, :max => (max.nil? ? total_issues : max)}
  end
  
end
