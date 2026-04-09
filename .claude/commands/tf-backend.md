---
description: Add a terraform_backend block to a YAML configuration file, deriving a unique state key from the file path and content.
argument-hint: <path to YAML config>
---

Read and follow `.github/prompts/tf-backend.prompt.md` exactly. Treat the argument below as `$input`.

$input = $ARGUMENTS

If the target file already contains a `terraform_backend:` block, inform the user and stop — do not overwrite.
