# AWS StdBase Bootstrap

Boilerplate with bootstrap scripts to create a Terraform Standard Base.

Use this repo and the RUNME.sh script to bootstrap new IaC projects for AWS,
and bootstrap new environments.

## Features

- auto create initial config files
- bootstrap remote s3 state per environment
- bootstrap first 3 domains

## Usage

Run `./RUNME.sh init_project` once

Run `./RUNME.sh bootstrap_infra_env` for every aws account that serves as a
seperate environment.

## Todo

### Next version

- [ ] add script to template repo
- [ ] normalize environment name (lowercase alphanumeric)
- [ ] domain skeleton function
- [ ] wouter: verplichte repo url default_tags
- [ ] add default tags
- [ ] implement asserts
    - [ ] full test
    - [ ] current directory valid
    - [ ] vars set?
    - [ ] permissions correct
    - [ ] existing setup in environment
    - [ ] check kms with alias default_kms
