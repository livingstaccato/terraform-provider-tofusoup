terraform {
  required_providers {
    tofusoup = {
      source  = "local/providers/tofusoup"
      version = "0.0.1108"
    }
  }
}

provider "tofusoup" {}

# Read the current state file (this example's own state)
data "tofusoup_state_info" "current" {
  state_path = "${path.module}/terraform.tfstate"
}

# Read a sample state file
data "tofusoup_state_info" "sample" {
  state_path = "${path.module}/sample-state.tfstate"
}
