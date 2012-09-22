module MorningPages
  class Folder
    def initialize(config = {})
      @dir = config[:dir]
      @file_extension = config[:file_extension] || ''
      if (@dir && !File.exists?(@dir))
        FileUtils.mkdir_p(@dir)
      end
    end

    def todays_words
      get_words_for(today_path)
    end

    def today_path
      File.expand_path([@dir, Time.now.strftime("%Y\-%m\-%d") + @file_extension].join('/'))
    end
    
    def get_words_for(path)
      (File.exists?(path) ? File.read(path) : "").split(" ")
    end
  end
end
