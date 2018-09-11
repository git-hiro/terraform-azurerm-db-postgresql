terragrunt = {
  remote_state {
    backend = "azurerm"

    config {
      resource_group_name  = "${get_env("TF_VAR_state_resource_group_name", "")}"
      storage_account_name = "${get_env("TF_VAR_state_storage_account_name", "")}"
      container_name       = "${get_env("TF_VAR_state_container", "")}"
      key                  = "${get_env("TF_VAR_environment", "")}.tfstate"
    }
  }

  terraform {
    extra_arguments "environment_tfvars" {
      commands = [
        "destroy",
        "import",
        "output",
        "plan",
        "push",
        "refresh",
      ]

      required_var_files = [
        "environments/${get_env("TF_VAR_environment", "")}.tfvars",
      ]
    }

    extra_arguments "retry_lock" {
      commands  = ["${get_terraform_commands_that_need_locking()}"]
      arguments = ["-lock-timeout=10m"]
    }
  }
}
