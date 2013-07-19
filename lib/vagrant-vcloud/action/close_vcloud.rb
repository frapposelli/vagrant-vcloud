require 'vcloud-rest/connection'

module VagrantPlugins
  module VCloud
    module Action
      class CloseVCloud
        def initialize(app, env)
          @app = app
        end

        def call(env)
          begin
            env[:vcloud_connection].logout
          rescue Exception => e
            #raise a properly namespaced error for Vagrant
            raise Errors::VCloudError, :message => e.message
          end
        end
      end
    end
  end
end
