require 'yaml'
require 'httparty'

module MorningPages
  class Config
    def initialize(opts)
      @config_path = opts[:config]
      containing_folder = File.dirname(@config_path)

      unless (File.exists?(containing_folder))
        FileUtils.mkdir_p(containing_folder)
      end

      @config = opts
      if (File.exists?(@config_path))
        @config = @config.merge(YAML.load(File.read(@config_path)))
      end
      @server = @config[:server]
    end
    
    def [](key)
      @config[key]
    end

    def registered?
      @config.include? :username
    end

    def register!(params)
      response = HTTParty.post("#{@server}/register", :body => params)
      return false if response.code != 200
      save(params.merge(:key => response.fetch("key")))
      write!
      true
    rescue Timeout::Error
      return false
    end

    def post_stats!(params)
      response = HTTParty.post("#{@server}/stats", :body => params.merge(:key => @config[:key]))
      return false if response.code != 200
      true
    rescue Timeout::Error
      return false
    end

    private

    def save(params)
      @config.merge!(params)
    end

    def write!
      File.open(@config_path, 'w') { |f| f.write(@config.to_yaml) }
    end
  end
end
