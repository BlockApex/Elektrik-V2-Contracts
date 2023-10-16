// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {SafeERC20} from "openzeppelin/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";

abstract contract Vault {
    using SafeERC20 for IERC20;

    function _receiveAsset(
        address asset,
        uint256 amount,
        address maker
    ) internal {
        IERC20 token = _asIERC20(asset);

        token.safeTransferFrom(maker, address(this), amount);
    }

    function _sendAsset(address asset, uint256 amount, address maker) internal {
        IERC20 token = _asIERC20(asset);
        token.safeTransfer(maker, amount);
    }

    function _asIERC20(address asset) internal pure returns (IERC20) {
        return IERC20(asset);
    }
}
