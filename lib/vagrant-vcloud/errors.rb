require "vagrant"

module VagrantPlugins
  module VCloud
    module Errors
      class VCloudError < Vagrant::Errors::VagrantError
        error_namespace("vagrant_vcloud.errors")
      end
      class RestError < VCloudError
        error_namespace("vagrant_vcloud.errors.rest_errors")
      	error_key(:rest_error)
      end
      class ObjectNotFound < RestError
        error_key(:object_not_found)
      end
      class InvalidConfigError < RestError
        error_key(:invalid_config_error)
      end
      class InvalidStateError < RestError
        error_key(:invalid_state_error)
      end
      class SyncError < VCloudError
        error_key(:sync_error)
      end
    end
  end
end
