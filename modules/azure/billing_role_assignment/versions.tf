terraform {
  required_providers {
    rest = {
      source  = "LaurentLesle/rest"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.0"
    }
  }
}
