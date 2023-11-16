// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

// OpenZeppelin imports
import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";
import {IERC1271} from "openzeppelin/interfaces/IERC1271.sol";
import {EIP712, ECDSA} from "openzeppelin/utils/cryptography/EIP712.sol";
import {Ownable2Step} from "openzeppelin/access/Ownable2Step.sol";
import {ReentrancyGuard} from "openzeppelin/security/ReentrancyGuard.sol";

// Custom libraries import
import {OrderEngine} from "./libraries/OrderEngine.sol";
import {Decoder} from "./libraries/Decoder.sol";

// Custom interfaces import
import {IPredicates} from "./interfaces/IPredicates.sol";
import {IPreInteractionNotificationReceiver} from "./interfaces/IPreInteractionNotificationReceiver.sol";
import {IPostInteractionNotificationReceiver} from "./interfaces/IPostInteractionNotificationReceiver.sol";
import {IFacilitatorInteractionNotificationReceiver} from "./interfaces/IFacilitatorInteractionNotificationReceiver.sol";

// Custom smart contracts import
import {Vault} from "./Vault.sol";
import "./AdvancedOrderEngineErrors.sol";

contract AdvancedOrderEngine is ReentrancyGuard, Vault, Ownable2Step, EIP712 {
    // TBD: consider making extraData a separate param
    // TBD: consider changing data type to IERC20 of buy and sell token

    using OrderEngine for OrderEngine.Order;
    using Decoder for bytes;

    /*//////////////////////////////////////////////////////////////
                           STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    // Used for precision in calculations.
    uint256 public constant ONE = 1e18;

    // EIP-712 domain name used for computing the domain separator.
    string private constant _NAME = "Elektrik Limit Order Protocol";

    // EIP-712 domain version used for computing the domain separator.
    string private constant _VERSION = "v1";

    // Address of the Predicates smart contract.
    IPredicates public predicates;

    // Tracks the amount of tokens sold for each order using the order hash.
    mapping(bytes32 => uint256) public filledSellAmount;

    // Tracks whether an address has operator privilege.
    mapping(address => bool) public isOperator;

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    event OrderFill(bytes32 orderHash, uint256 filledSellAmount);
    event OperatorAccessModified(address indexed authorized, bool access);
    event PredicatesChanged(address oldPredicateAddr, address newPredicateAddr);
    event OrderCanceled(bytes32 orderHash, uint256 filledSellAmount);

    /*//////////////////////////////////////////////////////////////
                             CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Constructor function to initialize predicates smart contract address and EIP712 domain separator.
     * @param predicatesAddr Address of the Predicates smart contract.
     */
    constructor(IPredicates predicatesAddr) EIP712(_NAME, _VERSION) {
        // Revert if the provided predicates address is zero address.
        if (address(predicatesAddr) == address(0)) {
            revert ZeroAddress();
        }
        predicates = predicatesAddr;
    }

    /*//////////////////////////////////////////////////////////////
                                MODIFIER
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Only allows the contract operator to call a function.
     */
    modifier onlyOperator() {
        // Revert if the caller is not an operator.
        if (!isOperator[msg.sender]) {
            revert NotAnOperator(msg.sender);
        }
        _;
    }

    /*//////////////////////////////////////////////////////////////
                      OWNER RESTRICTED FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Manage operator privileges for a specific address.
     * @dev Only callable by the owner.
     * @param operatorAddress Address for which operator privileges are being managed.
     * @param access Boolean indicating whether to grant (_access=true) or revoke (_access=false) operator privileges.
     */

    function manageOperatorPrivilege(
        address operatorAddress,
        bool access
    ) external onlyOwner {
        // Revert if the provided operator address is zero address.
        if (operatorAddress == address(0)) {
            revert ZeroAddress();
        }

        // Revert if the access status remains unchanged.
        if (isOperator[operatorAddress] == access) {
            revert AccessStatusUnchanged();
        }

        isOperator[operatorAddress] = access;

        emit OperatorAccessModified(operatorAddress, access);
    }

    /**
     * @notice Change the address of the predicates smart contract.
     * @dev Only callable by the owner.
     * @param newPredicateAddr New address of the predicates smart contract.
     */
    function changePredicateAddress(
        IPredicates newPredicateAddr
    ) external onlyOwner {
        // Revert if the new predicates smart contract address is zero address.
        if (address(newPredicateAddr) == address(0)) {
            revert ZeroAddress();
        }

        // TBD: test if this works
        // Revert if the new predicates smart contract address is the same as the current one.
        if (predicates == newPredicateAddr) {
            revert SamePredicateAddress();
        }

        // TBD: try to change predicate address in emit
        // TBD: Ipredicates data type in events?
        emit PredicatesChanged(address(predicates), address(newPredicateAddr));

        predicates = newPredicateAddr;
    }

    /*//////////////////////////////////////////////////////////////
                          FILL ORDER FUNCTION
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Fills multiple orders by processing the specified orders.
     * @dev Only callable by operators.
     * @param orders An array of order structs representing the orders to be filled.
     * @param executedSellAmounts An array of sell token amounts requested by the facilitator from order makers.
     * @param executedBuyAmounts An array of buy token amounts offered by the facilitator to the makers.
     * @param borrowedTokens An array of token addresses the facilitator wants to borrow from the vault.
     * @param borrowedAmounts An array specifying the corresponding amounts of each token the facilitator wants to borrow.
     * @param signatures An array of signatures, each corresponding to an order, used for order validation.
     * @param facilitatorInteraction Calldata for the facilitator's interaction.
     */
    function fillOrders(
        OrderEngine.Order[] calldata orders,
        uint256[] calldata executedSellAmounts,
        uint256[] calldata executedBuyAmounts,
        bytes[] calldata signatures,
        bytes calldata facilitatorInteraction,
        IERC20[] calldata borrowedTokens,
        uint256[] calldata borrowedAmounts
    ) external onlyOperator nonReentrant {
        _validateInputLengths(
            orders,
            executedSellAmounts,
            executedBuyAmounts,
            signatures
        );

        for (uint256 i; i < orders.length; ) {
            _processOrder(
                orders[i],
                executedSellAmounts[i],
                executedBuyAmounts[i],
                signatures[i]
            );

            unchecked {
                ++i;
            }
        }

        _processFacilitatorInteraction(
            facilitatorInteraction,
            orders,
            executedSellAmounts,
            executedBuyAmounts,
            borrowedTokens,
            borrowedAmounts
        );

        for (uint256 i; i < orders.length; ) {
            _processFinalizeOrder(
                orders[i],
                executedSellAmounts[i],
                executedBuyAmounts[i]
            );
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Cancels an on-chain order that has been signed offline.
     * @dev Cancels the order by setting the remaining amount to the order's sell token amount.
     * @param order Order to be canceled.
     */
    function cancelOrder(OrderEngine.Order calldata order) external {
        if (order.maker != msg.sender) {
            revert AccessDenied();
        }
        bytes32 orderHash = getOrderHash(order);
        uint256 currentFilledSellAmount = filledSellAmount[orderHash];
        if (currentFilledSellAmount == order.sellTokenAmount) {
            revert OrderFilledAlready();
        }
        emit OrderCanceled(orderHash, currentFilledSellAmount);
        filledSellAmount[orderHash] = order.sellTokenAmount;
    }

    function _validateInputLengths(
        OrderEngine.Order[] calldata orders,
        uint256[] calldata executedSellAmounts,
        uint256[] calldata executedBuyAmounts,
        bytes[] calldata signatures
    ) private pure {
        /**
         * @dev Checking for orders length not being zero is sufficient because in subsequent checks,
         *      we ensure that the length of each array should be the same. If any other array length is zero,
         *      it will revert in the subsequent check.
         */
        // Revert if the orders array length is zero.
        if (orders.length == 0) {
            revert EmptyOrdersArray();
        }

        // Revert if the length of any array (orders, executedSellAmounts, executedBuyAmounts, signatures) is not the same.
        if (
            orders.length != executedSellAmounts.length ||
            executedSellAmounts.length != executedBuyAmounts.length ||
            executedBuyAmounts.length != signatures.length
        ) {
            revert ArraysLengthMismatch();
        }
    }

    function _processOrder(
        OrderEngine.Order calldata order,
        uint256 executedSellAmount,
        uint256 executedBuyAmount,
        bytes calldata signature
    ) private {
        bytes32 orderHash = getOrderHash(order);

        _validateOrder(order, executedSellAmount, executedBuyAmount, orderHash);

        if (order.isPartiallyFillable) {
            _processPartiallyFillableOrder(
                order,
                orderHash,
                executedSellAmount,
                executedBuyAmount
            );
        } else {
            if (order.buyTokenAmount > executedBuyAmount) {
                revert LimitPriceNotRespected();
            }
            executedSellAmount = order.sellTokenAmount;
            filledSellAmount[orderHash] = executedSellAmount;
        }

        // Validate the signature.
        _validateOrderSignature(order, orderHash, signature);

        // Check predicate if it exists.
        if (order.predicateCalldata.length > 0) {
            if (!checkPredicate(order.predicateCalldata))
                revert PredicateIsNotTrue();
        }

        // Execute pre-interaction if needed.
        _executePreInteraction(
            order,
            orderHash,
            executedSellAmount,
            executedBuyAmount
        );

        // Receive sell tokens from the maker.
        _receiveAsset(order.sellToken, executedSellAmount, order.maker);
    }

    function _validateOrder(
        OrderEngine.Order calldata order,
        uint256 executedSellAmount,
        uint256 executedBuyAmount,
        bytes32 orderHash
    ) private view {
        // Revert if the order is expired.
        if (block.timestamp > order.validTill) {
            revert OrderExpired(orderHash);
        }

        // Revert if any amount in the order is zero.
        if (
            order.buyTokenAmount == 0 ||
            order.sellTokenAmount == 0 ||
            executedSellAmount == 0 ||
            executedBuyAmount == 0
        ) {
            revert ZeroAmount();
        }

        // Revert if any address in the order is zero.
        if (
            order.maker == address(0) ||
            address(order.buyToken) == address(0) ||
            address(order.sellToken) == address(0) ||
            order.recipient == address(0)
        ) {
            revert ZeroAddress();
        }

        // Revert if the private order is not sent by the operator.
        if (order.operator != address(0) && order.operator != msg.sender) {
            revert PrivateOrder();
        }

        // Revert if the order is already filled.
        // TBD: same msg even if order is cancelled
        if (filledSellAmount[orderHash] == order.sellTokenAmount) {
            revert OrderFilledAlready();
        }
    }

    function _processPartiallyFillableOrder(
        OrderEngine.Order calldata order,
        bytes32 orderHash,
        uint256 executedSellAmount,
        uint256 executedBuyAmount
    ) private {
        if (
            (executedSellAmount * ONE) / executedBuyAmount >
            (order.sellTokenAmount * ONE) / order.buyTokenAmount
        ) {
            revert LimitPriceNotRespected();
        }

        filledSellAmount[orderHash] += executedSellAmount;

        if (filledSellAmount[orderHash] > order.sellTokenAmount) {
            revert ExceedsOrderSellAmount();
        }
    }

    function _validateOrderSignature(
        OrderEngine.Order calldata order,
        bytes32 orderHash,
        bytes calldata signature
    ) private view {
        if (order.isContract()) {
            if (
                !(IERC1271(order.maker).isValidSignature(
                    orderHash,
                    signature
                ) == IERC1271.isValidSignature.selector)
            ) {
                revert InvalidSignature();
            }
        } else {
            address signer = ECDSA.recover(orderHash, signature);
            if (signer != order.maker) {
                revert InvalidSignature();
            }
        }
    }

    function _validateInteractionTarget(
        address interactionTarget
    ) private view {
        if (
            interactionTarget == address(this) ||
            interactionTarget == address(0)
        ) {
            revert InvalidInteractionTarget();
        }
    }

    function _executePreInteraction(
        OrderEngine.Order calldata order,
        bytes32 orderHash,
        uint256 executedSellAmount,
        uint256 executedBuyAmount
    ) private {
        if (order.preInteraction.length >= 20) {
            // proceed only if interaction length is enough to store address
            (address interactionTarget, bytes calldata interactionData) = order
                .preInteraction
                .decodeTargetAndCalldata();

            _validateInteractionTarget(interactionTarget);

            IPreInteractionNotificationReceiver(interactionTarget)
                .fillOrderPreInteraction(
                    orderHash,
                    order.maker,
                    executedSellAmount,
                    executedBuyAmount,
                    interactionData
                );
        }
    }

    function _processFacilitatorInteraction(
        bytes calldata facilitatorInteraction,
        OrderEngine.Order[] calldata orders,
        uint256[] calldata executedSellAmounts,
        uint256[] calldata executedBuyAmounts,
        IERC20[] calldata borrowedTokens,
        uint256[] calldata borrowedAmounts
    ) private {
        if (facilitatorInteraction.length >= 20) {
            // proceed only if interaction length is enough to store address
            (
                address interactionTarget,
                bytes calldata interactionData
            ) = facilitatorInteraction.decodeTargetAndCalldata();

            _validateInteractionTarget(interactionTarget);

            // Facilitator is expected to provide us with the token addresses and their corresponding amounts that they require from the vault.
            // TBD: consider using these returned values for some kinda balances assertion
            // TBD: is it alright to assume facilitator will ensure that duplicates addresses are not present in 'borrowedTokens' array?
            // considering gas fee will not be paid by the facilitator, so there's no benefit for facilitator to ensure this
            // TBD: transfer funds to 'interactionTarget' or no harm in expecting recipient address?

            if (borrowedTokens.length != borrowedAmounts.length) {
                revert ArraysLengthMismatch();
            }

            // Transferring funds to the address provided by the facilitator
            for (uint256 i; i < borrowedTokens.length; ) {
                _sendAsset(
                    borrowedTokens[i],
                    borrowedAmounts[i],
                    interactionTarget
                );
                unchecked {
                    ++i;
                }
            }

            IFacilitatorInteractionNotificationReceiver(interactionTarget)
                .fillOrderInteraction(
                    orders,
                    executedSellAmounts,
                    executedBuyAmounts,
                    borrowedTokens,
                    borrowedAmounts,
                    interactionData
                );
        }
    }

    function _processFinalizeOrder(
        OrderEngine.Order calldata order,
        uint256 executedSellAmount,
        uint256 executedBuyAmount
    ) private {
        bytes32 orderHash = getOrderHash(order);

        // Send buy tokens to the recipient.
        _sendAsset(order.buyToken, executedBuyAmount, order.recipient);

        // Execute post-interaction if needed.
        _executePostInteraction(
            order,
            orderHash,
            executedSellAmount,
            executedBuyAmount
        );

        // Emit an event for the order fill.
        emit OrderFill(orderHash, filledSellAmount[orderHash]);
    }

    function _executePostInteraction(
        OrderEngine.Order calldata order,
        bytes32 orderHash,
        uint256 executedSellAmount,
        uint256 executedBuyAmount
    ) private {
        if (order.postInteraction.length >= 20) {
            // proceed only if interaction length is enough to store address
            (address interactionTarget, bytes calldata interactionData) = order
                .postInteraction
                .decodeTargetAndCalldata();

            _validateInteractionTarget(interactionTarget);

            IPostInteractionNotificationReceiver(interactionTarget)
                .fillOrderPostInteraction(
                    orderHash,
                    order.maker,
                    executedSellAmount,
                    executedBuyAmount,
                    interactionData
                );
        }
    }

    /*//////////////////////////////////////////////////////////////
                            HELPER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Returns the EIP-712 domain separator for the current chain.
     * @return domainSeparator Unique identifier used for EIP-712 structured data hashing in this contract.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR()
        external
        view
        returns (bytes32 domainSeparator)
    {
        domainSeparator = _domainSeparatorV4();
    }

    /**
     * @notice Checks order predicate.
     * @param predicateCalldata Calldata of the predicate to be checked.
     * @return result Predicate evaluation result. True if the predicate allows filling the order, false otherwise.
     */
    function checkPredicate(
        bytes calldata predicateCalldata
    ) public view returns (bool result) {
        (bool success, uint256 res) = predicates.staticcallForUint(
            address(predicates),
            predicateCalldata
        );
        result = success && res == 1;
    }

    /**
     * @notice Computes hash for the provided order.
     * @param order Order to generate the hash for.
     * @return hash Unique hash representing the provided order.
     */
    function getOrderHash(
        OrderEngine.Order calldata order
    ) public view returns (bytes32 hash) {
        hash = _hashTypedDataV4(order.hash());
    }
}
