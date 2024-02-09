// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {SafeERC20} from "openzeppelin/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";

abstract contract Vault {
    using SafeERC20 for IERC20;

    function _receiveAsset(
        IERC20 token,
        uint256 amount,
        address maker
    ) internal {
        token.safeTransferFrom(maker, address(this), amount);
    }

    function _sendAsset(IERC20 token, uint256 amount, address maker) internal {
        token.safeTransfer(maker, amount);
    }
}
