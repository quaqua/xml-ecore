require 'logger'
require 'fileutils'
require 'yaml'

module Ecore
  class Auditing
    
    DELIMITER = "+=+"
    class << self
      
      # starts auditing any node changes
      def start
        @@logfile = ::File::join(ENV[:repos_path],"audit",ENV[:audit_logfile])
        FileUtils.mkdir_p(File::dirname(@@logfile)) unless File::exists?(File::dirname(@@logfile))
        @@audit_log = Logger.new(@@logfile,10,1024000)
        Ecore::log.info("Ecore::Auditing any repository changes to #{@@logfile}")
      end
      
      def log(operation, node,summary="")
        str = "#{DELIMITER}#{Time.now}"
        str << "#{DELIMITER}#{operation}"
        str << "#{DELIMITER}#{Time.now.to_f}"
        str << "#{DELIMITER}#{node.class.name}"
        str << "#{DELIMITER}#{node.name}"
        str << "#{DELIMITER}#{node.id}"
        str << "#{DELIMITER}#{summary}"
        if node.updated_by and node.updater
          str << "#{DELIMITER}#{node.updater.name}"
          str << "#{DELIMITER}#{node.updated_by}" 
        end
        str << DELIMITER
        @@audit_log.info(str)
      end
      
      def tail(num=50)
        filesize = File::size(@@logfile)
        num = filesize / 120 if (filesize / 120) < num
        IO.readlines(@@logfile)[(-1 * num)..-1].inject(Array.new) do |arr, line|
          if line.include?(DELIMITER)
            splitline = line.split(DELIMITER)
            tmp_hash = {:operation => splitline[2],
                        :time => Time.at(splitline[3].to_f), 
                        :class_name => splitline[4],
                        :name => splitline[5],
                        :id => splitline[6],
                        :summary => splitline[7]}
            tmp_hash.merge!({ :user_name => splitline[8],
                              :user_id => splitline[9]}) if splitline.size > 9
            arr << tmp_hash
          end
          arr
        end
      end
      
    end
  end
end