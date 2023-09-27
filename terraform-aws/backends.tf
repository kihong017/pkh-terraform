terraform {
  cloud {
    organization = "pkh-terraform"

    workspaces {
      name = "pkh-dev"
    }
  }
}