// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../preclude/Preclude.sol";

import "../context/ContextInterface.sol";
import "../eip712/HEIP712Interface.sol";
import "./HERC20Event.sol";

//import "@openzeppelin/contracts/interfaces/IERC2612.sol";

interface HERC20Interface is ContextInterface, HEIP712Interface, IERC20, IERC20Metadata, HERC20Event {

    function cap() external view returns (uint256);

    //======================IERC2612====================
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     *
     * CAUTION: See Security Considerations above.
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}
