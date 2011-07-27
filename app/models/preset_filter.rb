class PresetFilter
  PRESET_FILTERS = {:recently_added => 0, :recently_updated => 1, :recently_resolved => 2, 
                    :recently_closed => 3, :all => 4, :unassigned => 5, :assigned_to_me => 6}
  
  class << self
    def presets
      PRESET_FILTERS
    end
  end
end
