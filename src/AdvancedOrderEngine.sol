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

    // Address where fee is collected.
    address public feeCollector;

    // Stores the whitelist status of each token.
    mapping(IERC20 => bool) public isWhitelistedToken;

    // Tracks the amount of tokens sold for each order using the order hash.
    mapping(bytes32 => uint256) public filledSellAmount;

    // Tracks whether an address has operator privilege.
    mapping(address => bool) public isOperator;

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    event OrderFill(bytes32 orderHash, uint256 filledSellAmount);
    event OperatorAccessModified(address indexed authorized, bool access);
    event OrderCanceled(bytes32 orderHash, uint256 filledSellAmount);
    event FeeCollectorChanged(
        address oldFeeCollectorAddr,
        address newFeeCollectorAddr
    );
    event PredicatesChanged(
        address oldPredicatesAddr,
        address newPredicatesAddr
    );
    event WhitelistStatusUpdated(address indexed token, bool access);

    /*//////////////////////////////////////////////////////////////
                             CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Constructor function to initialize predicates smart contract address, fee collector address and EIP712 domain separator.
     * @param predicatesAddr Address of the Predicates smart contract.
     * @param feeCollectorAddr Address where protocol will collect fees.
     */
    constructor(
        IPredicates predicatesAddr,
        address feeCollectorAddr
    ) EIP712(_NAME, _VERSION) {
        // Revert if the provided predicates or fee collector address is a zero address.
        if (
            address(predicatesAddr) == address(0) ||
            feeCollectorAddr == address(0)
        ) {
            revert ZeroAddress();
        }

        feeCollector = feeCollectorAddr;
        predicates = predicatesAddr;

        emit FeeCollectorChanged(address(0), feeCollectorAddr);
        emit PredicatesChanged(address(0), feeCollectorAddr);
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
     * @notice Manages the whitelist status of tokens.
     * @dev Only callable by the owner.
     * @param tokens Array of token addresses to be whitelisted or removed from whitelist.
     * @param access Array of boolean values indicating whether to whitelist (true) a token or remove from whitelist (false).
     */
    function updateTokenWhitelist(
        IERC20[] calldata tokens,
        bool[] calldata access
    ) external onlyOwner {
        /**
         * @dev Checking for tokens length not being zero is sufficient because in subsequent checks,
         *      we ensure that the length of both tokens and access array should be the same. If access array length is zero,
         *      it will revert in the subsequent check.
         */
        // Revert if the tokens array length is zero.
        if (tokens.length == 0) {
            revert EmptyArray();
        }

        // Revert if the length of tokens and access array is not the same.
        if (tokens.length != access.length) {
            revert ArraysLengthMismatch();
        }

        for (uint256 i; i < tokens.length; ) {
            // Revert if the token address is a zero address.
            if (address(tokens[i]) == address(0)) {
                revert ZeroAddress();
            }

            // Revert if the access status remains unchanged.
            if (isWhitelistedToken[tokens[i]] == access[i]) {
                revert AccessStatusUnchanged();
            }

            isWhitelistedToken[tokens[i]] = access[i];

            emit WhitelistStatusUpdated(address(tokens[i]), access[i]);

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Change the address of the predicates smart contract.
     * @dev Only callable by the owner.
     * @param newPredicatesAddr New address of the predicates smart contract.
     */
    function changePredicateAddress(
        IPredicates newPredicatesAddr
    ) external onlyOwner {
        // Revert if the new predicates smart contract address is a zero address.
        if (address(newPredicatesAddr) == address(0)) {
            revert ZeroAddress();
        }

        // Local copy to save gas.
        IPredicates currentPredicates = predicates;

        // Revert if the new predicates smart contract address is the same as the current one.
        if (currentPredicates == newPredicatesAddr) {
            revert SamePredicateAddress();
        }

        emit PredicatesChanged(
            address(currentPredicates),
            address(newPredicatesAddr)
        );

        predicates = newPredicatesAddr;
    }

    /**
     * @notice Change address where fee is collected.
     * @dev Only callable by the owner.
     * @param newFeeCollectorAddr New address where protocol will collect fees.
     */
    function changeFeeCollectorAddress(
        address newFeeCollectorAddr
    ) external onlyOwner {
        // Revert if the new fee collector address is a zero address.
        if (newFeeCollectorAddr == address(0)) {
            revert ZeroAddress();
        }

        // Local copy to save gas.
        address currentFeeCollector = feeCollector;

        // Revert if the new fee collector address is the same as the current one.
        if (currentFeeCollector == newFeeCollectorAddr) {
            revert SameFeeCollectorAddress();
        }

        emit FeeCollectorChanged(currentFeeCollector, newFeeCollectorAddr);

        feeCollector = newFeeCollectorAddr;
    }

    /**
     * @notice collect leftover tokens.
     * @dev Only callable by the owner.
     * @param token token's contract address
     * @param amount amount you want to transfer
     * @param to address you want to transfer funds to
     */
    function withdraw (
        address token,
        uint amount,
        address to
    ) external onlyOwner {
        // Revert if the token address or the to address is a zero address.
        if (token == address(0) || to == address(0)) {
            revert ZeroAddress();
        }

        _sendAsset(IERC20(token), amount, to);

    }

    /*//////////////////////////////////////////////////////////////
                        ORDER PROCESSING FUNCTIONS
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
        // Validate that the lengths of input arrays are equal and non-empty.
        _validateInputArrays(
            orders,
            executedSellAmounts,
            executedBuyAmounts,
            signatures
        );

        // Loop through each order.
        for (uint256 i; i < orders.length; ) {
            /**
             * Process the current order by validating its integrity,
             * executing necessary actions, and eventually transferring funds from the maker to the vault.
             */
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

        // Execute facilitator interaction logic if defined.
        _processFacilitatorInteraction(
            facilitatorInteraction,
            orders,
            executedSellAmounts,
            executedBuyAmounts,
            borrowedTokens,
            borrowedAmounts
        );

        // Loop through each order again
        for (uint256 i; i < orders.length; ) {
            // Finalizes the execution of an order, sending buy tokens, executing post-interaction, and emitting a fill event.
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

    /*//////////////////////////////////////////////////////////////
                            UTILITY FUNCTIONS
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

    /*//////////////////////////////////////////////////////////////
                    ORDER PROCESSING HELPER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function _validateInputArrays(
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
            revert EmptyArray();
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

        // Validates essential conditions for processing an order and reverts if any checks fail.
        _validateOrder(order, executedSellAmount, executedBuyAmount, orderHash);

        uint256 executedFeeAmount;

        // If order is partially fillable.
        if (order.isPartiallyFillable) {
            // Processes a partially fillable order, validates the limit price, updates filled amounts, and calculates executed fee.
            executedFeeAmount = _processPartiallyFillableOrder(
                order,
                orderHash,
                executedSellAmount,
                executedBuyAmount
            );
        }
        // If the order is fill or kill.
        else {
            // Revert if order's limit price is not respected.
            if (order.buyTokenAmount > executedBuyAmount) {
                revert LimitPriceNotRespected();
            }

            executedSellAmount = order.sellTokenAmount;
            executedFeeAmount = order.feeAmounts;

            // Update the total filled sell amount for this order to match the order's original sell token amount.
            filledSellAmount[orderHash] = executedSellAmount;
        }

        // Verifies the signature of an order..
        _validateOrderSignature(order, orderHash, signature);

        // Check predicate if it exists.
        if (order.predicateCalldata.length > 0) {
            if (!checkPredicate(order.predicateCalldata))
                revert PredicateIsNotTrue();
        }

        // Execute pre-interaction logic for an order if defined.
        _executePreInteraction(
            order,
            orderHash,
            executedSellAmount,
            executedBuyAmount
        );

        // Receive sell tokens from the maker.
        _receiveAsset(order.sellToken, executedSellAmount, order.maker);

        // Receive fees from the maker to the fee collector address.
        _receiveAsset(order.sellToken, executedFeeAmount, feeCollector);
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

        // Revert if either the buy token or the sell token is not whitelisted.
        if (
            !isWhitelistedToken[order.buyToken] ||
            !isWhitelistedToken[order.sellToken]
        ) {
            revert TokenNotWhitelisted();
        }

        // Revert if buy token and sell token are equal
        if (
            order.sellToken == order.buyToken
        ) {
            revert SameBuyAndSellToken();
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
        if (filledSellAmount[orderHash] == order.sellTokenAmount) {
            revert OrderFilledAlready();
        }
    }

    function _processPartiallyFillableOrder(
        OrderEngine.Order calldata order,
        bytes32 orderHash,
        uint256 executedSellAmount,
        uint256 executedBuyAmount
    ) private returns (uint256 executedFeeAmount) {
        // Revert if order's limit price is not respected.
        if (
            (executedSellAmount * ONE) / executedBuyAmount >
            (order.sellTokenAmount * ONE) / order.buyTokenAmount
        ) {
            revert LimitPriceNotRespected();
        }

        // Update the total filled sell amount for this order.
        filledSellAmount[orderHash] += executedSellAmount;

        // Calculate the executed fee amount based on the proportion of the executed sell amount to the total sell amount.
        executedFeeAmount =
            (order.feeAmounts * executedSellAmount) /
            order.sellTokenAmount;

        // Revert if the total filled sell amount surpasses the order's original sell token amount.
        if (filledSellAmount[orderHash] > order.sellTokenAmount) {
            revert ExceedsOrderSellAmount();
        }
    }

    function _validateOrderSignature(
        OrderEngine.Order calldata order,
        bytes32 orderHash,
        bytes calldata signature
    ) private view {
        // If the order maker address is a smart contract address.
        if (order.isContract()) {
            if (
                !(IERC1271(order.maker).isValidSignature(
                    orderHash,
                    signature
                ) == IERC1271.isValidSignature.selector)
            ) {
                revert InvalidSignature();
            }
        }
        // If the order maker address it an EOA.
        else {
            address signer = ECDSA.recover(orderHash, signature);
            if (signer != order.maker) {
                revert InvalidSignature();
            }
        }
    }

    function _executePreInteraction(
        OrderEngine.Order calldata order,
        bytes32 orderHash,
        uint256 executedSellAmount,
        uint256 executedBuyAmount
    ) private {
        // Execute only if the order's preInteraction length is sufficient to store an address.
        if (order.preInteraction.length >= 20) {
            (address interactionTarget, bytes calldata interactionData) = order
                .preInteraction
                .decodeTargetAndCalldata();

            // Validate that the interaction target address is valid.
            _validateInteractionTarget(interactionTarget);

            // Invoke the fillOrderPreInteraction function on the interaction target contract.
            IPreInteractionNotificationReceiver(interactionTarget)
                .fillOrderPreInteraction(
                    orderHash,
                    order.maker,
                    executedSellAmount,
                    executedBuyAmount,
                    filledSellAmount[orderHash],
                    interactionData
                );
        }
    }

    function _validateInteractionTarget(
        address interactionTarget
    ) private view {
        // Revert if the interaction target is either the current contract or the zero address.
        if (
            interactionTarget == address(this) ||
            interactionTarget == address(0)
        ) {
            revert InvalidInteractionTarget();
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
        // Proceed only if facilitator interaction length is sufficient to store an address.
        if (facilitatorInteraction.length >= 20) {
            (
                address interactionTarget,
                bytes calldata interactionData
            ) = facilitatorInteraction.decodeTargetAndCalldata();

            // Validate that the interaction target address is valid.
            _validateInteractionTarget(interactionTarget);

            // Revert if the lengths of borrowed tokens and amounts arrays do not match.
            if (borrowedTokens.length != borrowedAmounts.length) {
                revert ArraysLengthMismatch();
            }

            // Transfer funds to the 'interactionTarget' address.
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

            // Invoke the fillOrderInteraction function on the facilitator interaction target contract.
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

        // Transfer the buy tokens to the recipient.
        _sendAsset(order.buyToken, executedBuyAmount, order.recipient);

        // Local copy to save gas.
        uint256 sellTokensFilled = filledSellAmount[orderHash];

        // Execute post-interaction logic for an order if defined.
        _executePostInteraction(
            order,
            orderHash,
            executedSellAmount,
            executedBuyAmount,
            sellTokensFilled
        );

        // Emit an event to log the order fill.
        emit OrderFill(orderHash, sellTokensFilled);
    }

    function _executePostInteraction(
        OrderEngine.Order calldata order,
        bytes32 orderHash,
        uint256 executedSellAmount,
        uint256 executedBuyAmount,
        uint256 sellTokensFilled
    ) private {
        // Execute only if the order's peostsInteraction length is sufficient to store an address.
        if (order.postInteraction.length >= 20) {
            (address interactionTarget, bytes calldata interactionData) = order
                .postInteraction
                .decodeTargetAndCalldata();

            // Validate that the interaction target address is valid.
            _validateInteractionTarget(interactionTarget);

            // Invoke the fillOrderPostInteraction function on the interaction target contract.
            IPostInteractionNotificationReceiver(interactionTarget)
                .fillOrderPostInteraction(
                    orderHash,
                    order.maker,
                    executedSellAmount,
                    executedBuyAmount,
                    sellTokensFilled,
                    interactionData
                );
        }
    }
}
