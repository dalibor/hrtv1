module Reports::Helpers
  # remove me
  include CurrencyNumberHelper # gives n2c method
  include StringCleanerHelper # gives h method
  extend ActiveSupport::Memoizable

  def codes_cache
    return @codes_cache if @codes_cache

    @codes_cache = {}
    Code.all.each do |code|
      @codes_cache[code.id] = code
    end

    return @codes_cache
  end

  def is_budget?(type)
    if type == :budget
      true
    elsif type == :spend
      false
    else
      raise "Invalid type #{type}".to_yaml
    end
  end

  def project_in_flows(project)
    project ? project.in_flows.map{ |f| f.from.name }.join(' | ') : ''
  end
end
