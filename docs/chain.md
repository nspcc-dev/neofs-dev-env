# Neo 3 privnet service

A single-node Neo3 privnet deployment running on
[neo-go](https://github.com/nspcc-dev/neo-go).

Contracts deployed:
- NeoFS [mainnet contract](https://github.com/nspcc-dev/neofs-contract)

## .env settings

### CHAIN_URL="https://fs.neo.org/dist/chain.gz"

URL to get main chain dump. Used on artifact get stage.

### CHAIN_PATH

Path to get main chain dump. If set, overrides `CHAIN_URL`.

### NEOGO_VERSION=0.91.1-pre-389-g71216865

Version on NeoGo container to use in both main privnet and sidechain.

## Main Privnet GAS

There is a wallet with GAS for both main privnet and side chain in
`wallets/wallet.json`.

```
$ neo-go wallet nep5 balance --token GAS \
    -w wallets/wallet.json \
    --addr NTrezR3C4X8aMLVg7vozt5wguyNfFhwuFx \
    -r http://main_chain.neofs.devenv:30333

TokenHash: 668e0c1f9d7b70a99dd9e06eadd4c784d641afbc
    Amount : 9987.92281340
    Updated: 13908
```

If you need GAS to deploy contracts on main privnet or create NeoFS account by
making deposits on NeoFS mainnet contract, you can transfer GAS from that
wallet.

Create new wallet

```
$ neo-go wallet init -a -w wallets/neofs1.json

Enter the name of the account > neofs1
Enter passphrase >
Confirm passphrase >

{
    "version": "3.0",
    "accounts": [
        {
            "address": "NXnzw3J9VvKXjM1BPAJK4QUpTtEQu4TpU6",
...
wallet successfully created, file location is wallets/neofs1.json
```

Transfer some GAS there
```
$ neo-go wallet nep5 transfer --privnet -w wallets/wallet.json \
    --from NTrezR3C4X8aMLVg7vozt5wguyNfFhwuFx \
    --to NXnzw3J9VvKXjM1BPAJK4QUpTtEQu4TpU6 \
    --amount 50 --token GAS \
    --rpc-endpoint http://main_chain.neofs.devenv:30333
```

Check it's there
```
$ neo-go wallet nep5 balance --token GAS \
    -w wallets/neofs1.json \
    --addr NXnzw3J9VvKXjM1BPAJK4QUpTtEQu4TpU6 \
    -r http://main_chain.neofs.devenv:30333

TokenHash: 668e0c1f9d7b70a99dd9e06eadd4c784d641afbc
    Amount : 50
    Updated: 14689
```

## Claim GAS from NEO on CN

If there is no enough GAS on `wallets/wallet.json` account, you can claim some
GAS from CN node's wallet from `services/chain/node-wallet.json` and then
transfer it. Wallet password can be found in
`services/chain/protocol.privnet.yml` file.

```
$ neo-go wallet claim -w services/chain/node-wallet.json \
    -a NVNvVRW5Q5naSx2k2iZm7xRgtRNGuZppAK \
    -r http://main_chain.neofs.devenv:30333

Password >
70e09bbd55846dcc7cee23905b737c63e5a80d32e387bce108bc6db8e641fb90
```

Then you can transfer GAS the same way as it was done in previous section.

```
neo-go wallet nep5 transfer --privnet -w services/chain/node-wallet.json \
    --from NVNvVRW5Q5naSx2k2iZm7xRgtRNGuZppAK \
    --to NXnzw3J9VvKXjM1BPAJK4QUpTtEQu4TpU6 \
    --amount 500 --token GAS \
    --rpc-endpoint http://main_chain.neofs.devenv:30333
```

## NeoFS GAS deposit

NeoFS identifies users by their Neo wallet key pair. To start using NeoFS in
devenv you need to transfer some GAS from Main privnet account to NeoFS main
contract's account by calling the `deposit` method.

First you need to get your account's LE encoded ScriptHash

```
$ neo-go util convert NXnzw3J9VvKXjM1BPAJK4QUpTtEQu4TpU6

Address to BE ScriptHash	82500e2e7de441e1b7378146ad91474f30fa1a0b
Address to LE ScriptHash	0b1afa304f4791ad468137b7e141e47d2e0e5082
Address to Base64 (BE)		glAOLn3kQeG3N4FGrZFHTzD6Ggs=
Address to Base64 (LE)		Cxr6ME9Hka1GgTe34UHkfS4OUII=
String to Hex				4e586e7a77334a3956764b586a4d314250414a4b3451557054744551753454705536
String to Base64			TlhuenczSjlWdktYak0xQlBBSks0UVVwVHRFUXU0VHBVNg==
```

And call the `deposit` method:
```
$ neo-go  contract invokefunction -w wallets/neofs1.json \
    -a NXnzw3J9VvKXjM1BPAJK4QUpTtEQu4TpU6 \
    -r http://main_chain.neofs.devenv:30333 \
    5f490fbd8010fd716754073ee960067d28549b7d \
    deposit 0b1afa304f4791ad468137b7e141e47d2e0e5082 \
    int:50 bytes: -- 0b1afa304f4791ad468137b7e141e47d2e0e5082

Enter account NXnzw3J9VvKXjM1BPAJK4QUpTtEQu4TpU6 password >
Sent invocation transaction 50e25f8e85c3b52dbd99381104cbe8056dad1a6e8809e8bf0e5d0a2527f55932
```
