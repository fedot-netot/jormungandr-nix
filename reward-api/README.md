# Usage

1. Using `nix-shell`

```
nix-shell --arg customConfig '{ rewardsLog = true; }'
```

2. Using `nixos` module

```
    services.jormungandr-reward-api.enable = true;
```

# API endpoints

The reward API endpoints give the rewards earned from an epoch, not the epoch the rewards were distributed.

For example, if stake is delegated in epoch 2, in epoch 4 the stake delegation from epoch 2 will be used, and the
rewards correspond to the amount delegated in epoch 4, not epoch 5 when the rewards were distributed.

## `/api/rewards/epoch/<epoch>`

Fetches all rewards data for a specific epoch

## `/api/rewards/account/<pubkey>`

Fetches all rewards details for a specific account public key

## `/api/rewards/pool/<poolid>`

Fetches all rewards details for a specific pool

## `/api/rewards/total`

Fetches aggregated rewards for blockchain since genesis

# Development

By default `FLASK_APP` points to nix store. To prevent having to exit the shell and
re-run the shell for every change, override it to the PATH in the current directory.

`FLASK_DEBUG` will reload on the application on every change to the python `app.py`
although it doesn't always work correctly.

```
nix-shell --arg customConfig '{ rewardsLog = true; }'
export FLASK_DEBUG=1
export FLASK_APP=reward-api/app.py
run-reward-api
```
