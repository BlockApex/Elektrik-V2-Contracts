# Vault Contract

The Vault contract within the Elektrik Limit Order Protocol's job is to handle asset transfers. It focuses on moving assets to and from the vault. The Vault contract contains three essential functions:

## \_receiveAsset

The `_receiveAsset` function is responsible for accepting asset deposits from makers and transferring them to the vault.

## \_sendAsset

The `_sendAsset` function is responsible in asset distribution within the protocol. It enables the transfer of assets from the vault to the intended recipient, which can be a facilitator or a maker.

## \_asIERC20

The `_asIERC20` function is used to convert an address into an IERC20 interface, allowing the protocol to interact with assets as ERC20 tokens.
