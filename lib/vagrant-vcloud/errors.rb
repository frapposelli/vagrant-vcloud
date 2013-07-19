require "vagrant"

module VagrantPlugins
  module VCloud
    module Errors
      class VCloudError < Vagrant::Errors::VagrantError
        error_namespace('vcloud.errors')
      end
      class RestError < VCloudError
      	error_key(:rest_error)
      end
      class SyncError < VCloudError
        error_key(:Sync_error)
      end
    end
  end
end
