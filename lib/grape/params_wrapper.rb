module Grape
  
  class ParamsWrapper
    attr_reader :params
    
    def initialize(params)
      @params = params
    end
    
    # define methods as needed
    def method_missing(name, *args)
      if @params.respond_to?(name)
        self.class.class_eval %{
          def #{name}(*params)
            @params.send(:#{name}, *params)
          end
        }
        
        send(name, *args)
      end
    end
    
    def has_key?(path)
      parts = split_path(path)
      _recursive_hash_key?(parts)
    end
    
    def read(path, curr = @params)
      parts = split_path(path)
      _recursive_read(parts)
    end
    
    def write(path, value)
      parts = split_path(path)
      _recursive_write(parts, value)
    end
  
  private
    def split_path(path)
      path.to_s.split('.')
    end
    
    def _recursive_hash_key?(path_parts, curr = @params)
      if curr.is_a?(Hash)
        if path_parts.size > 1
          key, *rest = path_parts
          _recursive_hash_key?(rest, curr[key])
          
        else
          curr.has_key?(path_parts[0])
        end
        
      else
        false
      end
    end
    
    def _recursive_read(path_parts, curr = @params)
      if curr.is_a?(Hash)
        if path_parts.size > 1
          key, *rest = path_parts
          _recursive_read(rest, curr[key])
          
        elsif curr.has_key?(path_parts[0])
          curr[path_parts[0]]
        end
        
      else
        nil
      end
    end
    
    def _recursive_write(path_parts, value, curr = @params)
      if curr.is_a?(Hash)
        if path_parts.size > 1
          key, *rest = path_parts
          _recursive_write(rest, value, curr[key])
          
        else
          curr[path_parts[0]] = value
        end
      end
      
      # always return nil
      nil
    end
    
  end
    
end
