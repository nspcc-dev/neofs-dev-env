<p align="center">
<img src="./.github/logo.svg" width="500px" alt="NeoFS">
</p>
<p align="center">
  <a href="https://fs.neo.org">NeoFS</a> local Development and Testing environment
</p>

---
## Overview

Tools to set up local NeoFS network and N3 privnets. Devenv, for short.

## Prerequisites

Make sure you have installed all of the following prerequisites on your machine:
* docker
* docker-compose
* make
* expect
* openssl
* jq
* base64 (coreutils)


## Quick Start

```
$ make up
```
When all services are up, you need to make GAS deposit for test wallet to be
able to pay for NeoFS operations. Test wallet is located in `wallets/wallet.json`
with the corresponding key in `wallets/wallet.key`. The password is empty.

```
$ make prepare.ir
password >
fa6ba62bffb04030d303dcc95bda7413e03aa3c7e6ca9c2f999d65db9ec9b82c
```
Also you should add self-signed node (`s04.neofs.devenv`) certificate to truststore 
(default location might be changed using `CA_CERTS_TRUSTED_STORE` variable). 
This step is required for client services (neofs-http-gw, neofs-s3-gw) to interact with the node:
```
$ sudo make prepare.storage
```

Change NeoFS global configuration values with `make update.*` commands. The
password of inner ring wallet is `one`. See examples in `make help`.

```
$ make update.epoch_duration val=30
Changing EpochDuration configration value to 30
Enter account NNudMSGzEoktFzdYGYoNb3bzHzbmM1genF password > 
Sent invocation transaction dbb8c1145b6d10f150135630e13bb0dc282023163f5956c6945a60db0cb45cb0
Updating NeoFS epoch to 2
Enter account NNudMSGzEoktFzdYGYoNb3bzHzbmM1genF password > 
Sent invocation transaction 0e6eb5e190f36332e5e5f4e866c7e100826e285fd949e11c085e15224f343ba6
```

You can see the addresses and hostnames of components with `make hosts` command.

```
$ make hosts
192.168.130.10 bastion.neofs.devenv
192.168.130.50 main_chain.neofs.devenv
192.168.130.61 ir01.neofs.devenv
...
192.168.130.74 s04.neofs.devenv
```

It's recommended to add `make hosts` output to your local `/etc/hosts` file.

For instructions on how to set up DevEnv on macOS, please refer [the
guide](docs/macOS.md) in `docs` directory.

## How it's organized

```
.
├── Makefile         # Commands to manage devenv
├── .services        # List of services to work with
├── services         # Services definitions and files
│   ├── basenet
│   ├── chain
│   ├── ir
│   ├── morph_chain
│   └── storage
├── vendor           # Temporary files and artifacts
└── wallets          # Wallet files to manage GAS assets
```

Main commands and targets to manage devenv's services are in `Makefile`.

Each service is defined in it's own directory under `services/` with all
required files to run and scripts to get external artifacts or dependencies.

The list of services and the starting order is defined in `.services` file. You
can comment out services you don't want to start or add your own new services.

You can find more information on each service in `docs` directory.

Maybe you will find the answer for your question in [F.A.Q.](docs/faq.md)

## Notable make targets

`make help` will print the brief description of available targets. Here we
describe some of them in a more detailed way.

### up

Start all Devenv services.

This target call `pull` to get container images, `get` to download required
artifacts, `vendor/hosts` to generate hosts file and then starts all services in
the order defined in `.services` file.

### down

Shutdowns all services. This will destroy all containers and networks. All
changes made inside containers will be lost.

### hosts

Display addresses and host names for each running service, if available.

### clean

Clean up `vendor` directory.

## Contributing

Feel free to contribute to this project after reading the [contributing
guidelines](CONTRIBUTING.md).

Before starting to work on a certain topic, create an new issue first,
describing the feature/topic you are going to implement.

# License

- [GNU General Public License v3.0](LICENSE)
