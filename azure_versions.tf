terraform {
  required_version = ">= 1.8.0"
  required_providers {
    rest = {
      source  = "LaurentLesle/rest"
      version = "= 1.2.0"
    }
    kind = {
      source  = "tehcyx/kind"
      version = "~> 0.7"
    }
    tls = {
      source  = "hashicorp/tls"
      version = ">= 4.0"
    }
  }
}
