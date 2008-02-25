require 'git/repo'

module Git

  class Repo

    class Object
      def show
        repo.in_work_tree do
          system("git","show",sha1)
        end
      end
    end

    def self.irb_start

      require 'irb'
      IRB.setup(::File.basename($0,".rb"))

      repo = nil
      begin
        repo = Git::Repo.new
      rescue Git::Repo::Error
        puts $!
        exit 1
      end

      def repo.to_s
        "git"
      end
      def repo.inspect
        "self"
      end
      irb = IRB::Irb.new(IRB::WorkSpace.new(repo))

      IRB.conf[:IRB_RC].call(irb.context) if IRB.conf[:IRB_RC]
      IRB.conf[:MAIN_CONTEXT] = irb.context

      trap("SIGINT") { irb.signal_handle }
      catch(:IRB_EXIT) { irb.eval_input }
    end

  end
end
