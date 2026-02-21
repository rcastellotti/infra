# envs

Use one workspace per node so state stays isolated while config stays identical.

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
