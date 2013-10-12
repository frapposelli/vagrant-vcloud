require "vagrant"

module VagrantPlugins
  module VCloud
    module Errors
      class VCloudError < Vagrant::Errors::VagrantError
        error_namespace("vagrant_vcloud.errors")
      end
      class VCloudOldVersion < VCloudError
        error_key(:vcloud_old_version)
      end
      class CatalogAddError < VCloudError
        error_key(:catalog_add_error)
      end
      class HostNotFound < VCloudError
        error_key(:host_not_found)
      end
      class HostRedirect < VCloudError
        error_key(:host_redirect)
      end
      class UnauthorizedAccess < VCloudError
        error_key(:unauthorized_access)
      end
      class StopVAppError < VCloudError
        error_key(:stop_vapp_error)
      end
      class ComposeVAppError < VCloudError
        error_key(:compose_vapp_error)
      end
      class InvalidNetSpecification < VCloudError
        error_key(:invalid_network_specification)
      end
      class ForwardPortCollision < VCloudError
        error_key(:forward_port_collision)
      end
      class SubnetErrors < VCloudError
        error_namespace("vagrant_vcloud.errors.subnet_errors")
      end
      class InvalidSubnet < SubnetErrors
        error_key(:invalid_subnet)
      end
      class SubnetTooSmall < SubnetErrors
        error_key(:subnet_too_small)
      end
      class RestError < VCloudError
        error_namespace("vagrant_vcloud.errors.rest_errors")
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
