# envs

Use one workspace per node so state stays isolated while config stays identical.
Terraform now creates a reusable 90-day Tailscale auth key via the Tailscale provider.

## tailscale OAuth app

1. In Tailscale admin, open **Trust credentials** and create an **OAuth** credential.
2. Scope: select only **Auth keys (write)** (`auth_keys`).
3. `fnox set` OAuth **client ID** (`TAILSCALE_OAUTH_CLIENT_ID`) and **client secret** (`TAILSCALE_OAUTH_CLIENT_ID`).
4. make sure the tag is declared in ACL

```json
"tagOwners": {
    "tag:rcastellotti-dev": ["autogroup:admin"]
}
```

make sure to add `"tag:rcastellotti-dev"` to SSH `dst`.

## dev

```sh
fnox exec -- terraform workspace select dev || fnox exec -- terraform workspace new dev
fnox exec -- terraform apply -var-file=envs/dev.tfvars
```

## prod

```sh
fnox exec -- terraform workspace select prod || fnox exec -- terraform workspace new prod
fnox exec -- terraform apply -var-file=envs/prod.tfvars
```
