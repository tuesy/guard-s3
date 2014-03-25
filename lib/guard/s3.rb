begin
  require 'aws/s3'
rescue LoadError => e
  e.message << " (You may need to install the aws-s3 gem)"
  raise e
end unless defined?(AWS::S3)

require 'guard'
require 'guard/plugin'

module Guard
  class S3 < Plugin
    include AWS::S3
    attr_reader :s3_connection, :pwd

    def initialize(watchers = [], options = {})
      super
      @s3_connection = Base.establish_connection!(
        :access_key_id  => options[:access_key_id],
        :secret_access_key => options[:secret_access_key]
      )
      @bucket         = options[:bucket]
      @s3_permissions = options[:s3_permissions]
      @debug          = true
      @watchdir       = (Dsl.options[:watchdir] && File.expand_path(Dsl.options[:watchdir])) || Dir.pwd
    end

    def run_on_change(paths)
      paths.each do |path|
        file  = File.join(@watchdir, path)
        begin
          if exists?(file)
            log "Nothing uploaded. #{file} already exists!"
          else
            log "Uploading #{path}"
            S3Object.store(path, open(file), @bucket, {:access => @s3_permissions})
          end
        rescue Exception => e
          log e.message
        end
      end
    end

    def exists?(filename)
      filename.nil? ? false : AWS::S3::S3Object.exists?(filename, @bucket)
    end

    private

    def debug?
      @debug || false
    end

    def log(msg)
      return unless debug?
      puts "[#{Time.now}] #{msg}"
    end

  end
end
