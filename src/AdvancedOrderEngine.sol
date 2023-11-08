// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {EIP712, ECDSA} from "openzeppelin/utils/cryptography/EIP712.sol";
import {IERC1271} from "openzeppelin/interfaces/IERC1271.sol";
import {OrderEngine} from "./libraries/OrderEngine.sol";
import {IPreInteractionNotificationReceiver} from "./interfaces/IPreInteractionNotificationReceiver.sol";
import {IPostInteractionNotificationReceiver} from "./interfaces/IPostInteractionNotificationReceiver.sol";
import {IPredicates} from "./interfaces/IPredicates.sol";

import {IInteractionNotificationReceiver} from "./interfaces/IInteractionNotificationReceiver.sol";

import {Decoder} from "./libraries/Decoder.sol";
import "./AdvancedOrderEngineErrors.sol";
import {Vault} from "./Vault.sol";
import {Ownable2Step} from "openzeppelin/access/Ownable2Step.sol";

contract AdvancedOrderEngine is Vault, Ownable2Step, EIP712 {
    // TBD: consider making extraData a separate param
    // TBD: consider making interfaces generic
    // TBD: consider changing data type to IERC20 of buy and sell token
    // TBD: consider allowing facilitator to tell offeredAmounts in its interaction

    using OrderEngine for OrderEngine.Order;
    using Decoder for bytes;

    // TBD: not using IPredicate type for now as it requires me to typecast to address many times
    address public predicates;

    mapping(address => bool) public isOperator;

    event OrderFill(
        address operator,
        address maker,
        bytes32 orderHash,
        uint256 offeredAmount
    );
    event OperatorAccessModified(address indexed authorized, bool access);
    event PredicatesChanged(address oldPredicateAddr, address newPredicateAddr);

    constructor(
        string memory name,
        string memory version,
        address _predicate
    ) EIP712(name, version) {
        if (_predicate == address(0)) {
            revert ZeroAddress();
        }
        predicates = _predicate;
    }

    modifier onlyOperator() {
        if (!isOperator[msg.sender]) {
            revert NotAnOperator(msg.sender);
        }
        _;
    }

    function manageOperatorPrivilege(
        address _address,
        bool _access
    ) external onlyOwner {
        if (_address == address(0)) {
            revert ZeroAddress();
        }

        // TBD: should we not allow if owner is trying to set same access? (con: additional gas)
        // Overwrites the access previously granted.
        isOperator[_address] = _access;

        emit OperatorAccessModified(_address, _access);
    }

    function setPredicateAddress(address _newPredicateAddr) external onlyOwner {
        if (_newPredicateAddr == address(0)) {
            revert ZeroAddress();
        }

        emit PredicatesChanged(predicates, _newPredicateAddr);

        // TBD: should we not allow if owner is trying to set same address? (con: additional gas)
        // Overwrites the access previously granted.
        predicates = _newPredicateAddr;
    }

    function checkPredicate(
        bytes calldata predicate
    ) public view returns (bool) {
        (bool success, uint256 res) = IPredicates(predicates).staticcallForUint(
            predicates,
            predicate
        );
        return success && res == 1;
    }

    /**
     * @notice Fills multiple orders by processing the specified orders and clearing prices.
     *
     * @param orders An array of order structs representing the orders to be filled.
     * @param offeredAmounts An array of clearing prices that the facilitator is offering to the makers.
     * @param facilitatorInteraction The calldata for the facilitator's interaction.
     */
    function fillOrders(
        OrderEngine.Order[] calldata orders,
        uint256[] calldata offeredAmounts,
        bytes[] calldata signatures,
        bytes calldata facilitatorInteraction
    ) external onlyOperator {
        // TBD: Private orders?

        // TBD: max array length check needed? Considering fn will be restricted to operators only

        /** 
            TBD: no need to check for offeredAmounts length to be equal to 0 as if that's the case, txn will revert in subsequent check
            but should we check for offeredAmounts length to be equal to zero explicitly for better error reporting? 
            Also consider generic error message
        */
        // Revert if the orders array length is zero.
        if (orders.length == 0) {
            revert EmptyOrdersArray();
        }

        // Revert if the length of the orders array does not match the clearing prices array.
        if (orders.length != offeredAmounts.length) {
            revert ArraysLengthMismatch();
        }

        for (uint256 i; i < orders.length; ) {
            OrderEngine.Order calldata order = orders[i];
            bytes calldata signature = signatures[i];

            bytes32 orderHash = order.hash();
            bytes32 orderMessageHash = _hashTypedDataV4(orderHash);

            if (block.timestamp > order.validTill) {
                revert OrderExpired(orderHash);
            }

            if (order.buyTokenAmount == 0 || order.sellTokenAmount == 0) {
                revert ZeroTokenAmounts();
            }

            if (
                order.maker == address(0) ||
                order.buyToken == address(0) ||
                order.sellToken == address(0) ||
                order.recipient == address(0)
            ) {
                revert ZeroAddress();
            }

            // STUB: PARTIAL FILL FEATURE //

            // TBD: debatable, can take signing scheme in order schema or can verify like 1inch
            if (order.isContract()) {
                if (
                    !(IERC1271(order.maker).isValidSignature(
                        orderMessageHash,
                        signature
                    ) == IERC1271.isValidSignature.selector)
                ) {
                    revert BadSignature();
                }
            } else {
                address signer = ECDSA.recover(orderMessageHash, signature);
                if (signer != order.maker) {
                    revert BadSignature();
                }
            }

            if (order.predicates.length > 0) {
                if (!checkPredicate(order.predicates))
                    revert PredicateIsNotTrue();
            }

            if (order.preInteraction.length >= 20) {
                // proceed only if interaction length is enough to store address
                (
                    address interactionTarget,
                    bytes calldata interactionData
                ) = order.preInteraction.decodeTargetAndCalldata();
                IPreInteractionNotificationReceiver(interactionTarget)
                    .fillOrderPreInteraction(
                        orderMessageHash,
                        order.maker,
                        offeredAmounts[i],
                        interactionData
                    );
            }

            // TODO: reorder params type
            _receiveAsset(order.sellToken, order.sellTokenAmount, order.maker);

            unchecked {
                ++i;
            }
        }

        if (facilitatorInteraction.length >= 20) {
            // proceed only if interaction length is enough to store address
            (
                address interactionTarget,
                bytes calldata interactionData
            ) = facilitatorInteraction.decodeTargetAndCalldata();

            // Facilitator is expected to provide us with the token addresses and their corresponding amounts that they require from the vault.
            // TBD: consider using these returned values for some kinda balances assertion
            // TBD: is it alright to assume facilitator will ensure that duplicates addresses are not present in 'tokenAddresses' array?
            // considering gas fee will not be paid by the facilitator, so there's no benefit for facilitator to ensure this
            // TBD: transfer funds to 'interactionTarget' or no harm in expecting recipient address?
            (
                address[] memory tokenAddresses,
                uint256[] memory tokenAmounts,
                address assetsRecipient
            ) = IInteractionNotificationReceiver(interactionTarget)
                    .getFacilitatorTokenTransferDetails(
                        msg.sender,
                        orders,
                        offeredAmounts
                    );

            if (tokenAddresses.length != tokenAmounts.length) {
                revert ArraysLengthMismatch();
            }

            if (assetsRecipient == address(0)) {
                revert ZeroAddress();
            }

            // Transferring funds to the address provided by the facilitator
            for (uint256 i; i < tokenAddresses.length; ) {
                _sendAsset(tokenAddresses[i], tokenAmounts[i], assetsRecipient);
                unchecked {
                    ++i;
                }
            }

            IInteractionNotificationReceiver(interactionTarget)
                .fillOrderInteraction(
                    msg.sender,
                    orders,
                    offeredAmounts,
                    interactionData
                );
        }

        // TODO: Need optimization
        for (uint256 i; i < orders.length; ) {
            OrderEngine.Order calldata order = orders[i];

            bytes32 orderHash = order.hash();
            bytes32 orderMessageHash = _hashTypedDataV4(orderHash);

            if (order.buyTokenAmount > offeredAmounts[i]) {
                revert LimitPriceNotRespected(
                    order.buyTokenAmount,
                    offeredAmounts[i]
                );
            }

            // TODO: reorder params type
            _sendAsset(order.buyToken, offeredAmounts[i], order.recipient);

            if (order.postInteraction.length >= 20) {
                // proceed only if interaction length is enough to store address
                (
                    address interactionTarget,
                    bytes calldata interactionData
                ) = order.postInteraction.decodeTargetAndCalldata();
                IPostInteractionNotificationReceiver(interactionTarget)
                    .fillOrderPostInteraction(
                        orderMessageHash,
                        order.maker,
                        offeredAmounts[i],
                        interactionData
                    );
            }

            // TODO: decide where to emit event, as its considered as an effect so maybe do it somewhere in the start; what params to log;
            // events spam? ; consider emitting just one event
            emit OrderFill(
                msg.sender,
                order.maker,
                orderMessageHash,
                offeredAmounts[i]
            );

            unchecked {
                ++i;
            }
        }
    }
}
