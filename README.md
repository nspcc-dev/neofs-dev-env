<p align="center">
<img src="./.github/logo.svg" width="500px" alt="NeoFS">
</p>
<p align="center">
  <a href="https://fs.neo.org">NeoFS</a> local Development and Testing environment
</p>

---
## Overview

Tools to setup local NeoFS network and Neo 3 privnet.

## Quick Start

```
$ make up
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

## Contributing

Feel free to contribute to this project after reading the [contributing
guidelines](CONTRIBUTING.md).

Before starting to work on a certain topic, create an new issue first,
describing the feature/topic you are going to implement.

# License

- [GNU General Public License v3.0](LICENSE)
