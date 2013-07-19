require "log4r"
require "vagrant/util/subprocess"
require "vagrant/util/scoped_hash_override"
require "unison"

module VagrantPlugins
  module VCloud
    module Action
      class SyncFolders
        include Vagrant::Util::ScopedHashOverride

        def initialize(app, env)
          @app    = app
          @logger = Log4r::Logger.new("vagrant_vcloud::action::sync_folders")
        end

        def call(env)
          @app.call(env)

          ### COMPLETELY REDO USING UNISON!!!!

        end
      end
    end
  end
end
