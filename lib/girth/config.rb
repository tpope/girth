require 'girth/mixin'

module Git
  class Repo::Config

    include Git::Repo::Mixin

    def initialize(repo, include_global = true)
      @repo, @include_global = repo, include_global
    end

    def inspect #:nodoc:
      if @include_global
        super("config")
      else
        super("config(#{false.inspect})")
      end
    end

    def set(key, value, value_regex = nil)
      exec(key, value, value_regex)
    end

    def add(key, value)
      exec("--add", key, value)
    end

    def unset(key, value_regex = nil)
      exec("--unset", key, value_regex)
    end

    def unset_all(key, value_regex = nil)
      exec("--unset-all", key, value_regex)
    end

    def rename_section(old,new)
      exec("--rename-section",old,new)
    end

    def remove_section(name)
      exec("--remove-section",name)
    end

    def get(key, pattern = nil)
      exec("--get",key)
    end

    def get_boolean(key, pattern = nil)
      value = exec("--bool","--get",key)
      case value
      when "true"  then true
      when "false" then false
      when ""      then nil
      else raise TypeError, "unknown boolean #{value}"
      end
    end

    def get_integer(key, pattern = nil)
      value = exec("--int","--get",key)
      case value
      when "" then nil
      else Integer(value)
      end
    end

    def to_h(nested = false)
      hash = {}
      with_environment do
        git.exec("config","--list") do |line|
          key, value = line.chomp.split("=",2)
          if nested
            superkey, subkey = key.match(/(.*)\.(.*)/).to_a[1,2]
            hash[superkey] ||= {}
            hash[superkey][subkey.tr('-_','_-').to_sym] = value
          else
            hash[key] = value
          end
        end
      end
      hash
    end

    def exec(*args) #:nodoc:
      with_environment do
        git.exec("config",*args.compact.map {|k| format(k)}).chomp
      end
    end

    private
    def format(key)
      key.kind_of?(String) ? key.dup : key.to_s.tr('-_', '_-')
    end

    def with_environment
      saved = ENV["GIT_CONFIG"]
      ENV["GIT_CONFIG"] = @include_global ? nil : "#{repo.git_dir}/config"
      yield
    ensure
      ENV["GIT_CONFIG"] = saved
    end

  end
end
