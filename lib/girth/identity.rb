module Girth
  # Encapsulates a user's name, email, and optionally a timestamp.
  class Identity

    attr_accessor :name, :email

    def initialize(name, email, timestamp = nil)
      @name, @email = name, email
      if timestamp
        @time = timestamp.to_i
        if timestamp.respond_to?(:utc_offset)
          self.zone = timestamp.utc_offset/60
        else
          self.zone = "+0000"
        end
      end
    end

    # Creates a identity from a string in either of the following forms:
    #
    #   "My Name <my@email> 1234567890 +0000"
    #   "My Name <my@email>"
    def self.parse(string)
      if match_data = string.match(/^(.*) <(.*)> (-?\d+) ([+-]\d+)$/)
        identity = Identity.new(match_data[1], match_data[2], match_data[3].to_i)
        identity.zone = match_data[4]
        identity
      elsif match_data = string.match(/^(.*) <(.*)>$/)
        Identity.new(match_data[1], match_data[2])
      else
        raise Girth::Error, "invalid identity #{string}"
      end
    end

    # Sets the GIT_WHATEVER_{NAME,DATE,EMAIL} variables for the duration of
    # the given block.
    #
    #   identity.as(:author, :committer) do
    #     # Something that generates a commit
    #   end
    def as(*types)
      saved = {}
      types.each do |type|
        %w(name email date).each do |aspect|
          key = "GIT_#{type.to_s.upcase}_#{aspect.upcase}"
          saved[key] = ENV[key]
          ENV[key]   = send(aspect)
        end
      end
      yield
    ensure
      ENV.update(saved)
    end

    # Offset in seconds from UTC.
    def utc_offset
      return unless @zone
      abs_minutes = @zone[1,2].to_i * 60 + @zone[3,2].to_i
      (@zone[0] == ?- ? -1 : 1) * abs_minutes * 60
    end

    # Accepts either a string representation ("-0600") or an offset in minutes.
    def zone=(zone)
      case zone
      when/^[+-]\d{4}/ then @zone = zone
      when Integer     then @zone = zone_from_minute_offset(zone)
      else
        raise TypeError, "invalid time zone #{zone.inspect}"
      end
    end

    # Canonical string format for an identity.  The default timestamp is based
    # on the current time.
    def to_s
      now = Time.now
      zone = @zone || zone_from_minute_offset(now.utc_offset/60)
      "#@name <#{email}> #{(@time || now).to_i} #{zone}"
    end

    def git_regexp #:nodoc:
      "\\<" + "#@name <#{email}>".sub(/([.*\\^$\[\]])/,'\\\\\\1')
    end

    def inspect #:nodoc:
      "#<#{self.class.inspect} #@name <#@email> #{date}>"
    end

    # Date string that git groks
    def date
      "#{(time.utc+utc_offset).ctime} #{@zone||"+0000"}" if @time
    end

    def time
      if @time
        time = Time.at(@time)
        @zone == "+0000" ? time.utc : time
      end
    end

    private
    def zone_from_minute_offset(offset)
      "%s%02d%02d" % [offset < 0 ? "-" : "+", offset.abs/60, offset.abs%60]
    end

  end
end
