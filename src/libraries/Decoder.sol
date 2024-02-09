// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "../AdvancedOrderEngineErrors.sol";

library Decoder {
    function decodeTargetAndCalldata(
        bytes calldata data
    ) internal pure returns (address target, bytes calldata args) {
        if (data.length < 20) revert IncorrectDataLength();
        // no memory ops inside so this insertion is automatically memory safe
        assembly {
            // solhint-disable-line no-inline-assembly
            target := shr(96, calldataload(data.offset))
            args.offset := add(data.offset, 20)
            args.length := sub(data.length, 20)
        }
    }
}
