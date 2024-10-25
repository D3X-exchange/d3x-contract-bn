// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/Context.sol";
//import "contracts/interface/IChildToken.sol";

contract D3xToken is Context, ERC20Capped, EIP712/*, IChildToken*/ {

    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet internal _minters;
    EnumerableSet.AddressSet internal _burners;
    EnumerableSet.AddressSet internal _depositors;

    struct Signature {
        bytes32 r;
        bytes32 s;
        uint8 v;
    }

    //only use for call this(self) contract, without value
    struct MetaTransaction {
        uint256 nonce;
        address from;
        bytes functionSignature;
    }

    event MetaTransactionExecuted(
        address userAddress,
        address relayerAddress,
        bytes functionSignature
    );

    bytes32 internal constant META_TRANSACTION_TYPEHASH = keccak256(
        bytes(
            "MetaTransaction(uint256 nonce,address from,bytes functionSignature)"
        )
    );

    mapping(address account => uint256) internal _nonces;

    constructor()
    ERC20Capped(100 * (10 ** 6) * (10 ** 18)) ERC20("ProsperEx", "PPE")
    EIP712("ProsperEx", "1"){

    }

    //  712 supported 'forward tx'
    function executeMetaTransaction(
        MetaTransaction calldata metaTx,
        Signature calldata signature
    ) public payable returns (bytes memory) {

        require(metaTx.nonce == _nonces[metaTx.from], "wrong nonce");

        require(verifyMetaTransaction(metaTx, signature), "Signer and signature do not match");

        // increase nonce for user (to avoid re-use)
        _nonces[metaTx.from] += 1;

        emit MetaTransactionExecuted(
            metaTx.from,
            msg.sender,
            metaTx.functionSignature
        );

        // Append userAddress and relayer address at the end to extract it from calling context
        (bool success, bytes memory returnData) = address(this).call(
            abi.encodePacked(metaTx.functionSignature, metaTx.from)
        );
        require(success, "Function call not successful");

        return returnData;
    }


    function verifyMetaTransaction(
        MetaTransaction calldata metaTx,
        Signature calldata signature
    ) public view returns (bool) {
        require(metaTx.from != address(0), "NativeMetaTransaction: INVALID_SIGNER");
        return
            metaTx.from ==
            ecrecover(
                getMetaTransaction712Hash(metaTx),
                signature.v,
                signature.r,
                signature.s
            );
    }


    function getMetaTransactionHash(MetaTransaction memory metaTx) public pure returns (bytes32)    {
        bytes32 dataHash = keccak256(abi.encode(
            META_TRANSACTION_TYPEHASH,
            metaTx.nonce,
            metaTx.from,
            keccak256(metaTx.functionSignature)//bytes goes to hash of itself
        ));

        return dataHash;
    }

    function getMetaTransaction712Hash(MetaTransaction memory metaTx) public view returns (bytes32)    {

        bytes32 structHash = getMetaTransactionHash(metaTx);

        return _hashTypedDataV4(structHash);
    }

    //======================

    //lycrus  需要检查写列表
    // Mint tokens (called by our ecosystem contracts)
    function mint(address to, uint amount) external {
        require(_minters.contains(_msgSender()));
        _mint(to, amount);
    }

    //lycrus  需要检查写列表
    // Burn tokens (called by our ecosystem contracts)
    function burn(address from, uint amount) external {
        require(_burners.contains(_msgSender()));
        _burn(from, amount);
    }

    /*
     * @notice called when token is deposited on root chain
     * @dev Should be callable only by ChildChainManager
     * Should handle deposit by minting the required amount for user
     * Make sure minting is done only by this function
     * @param user user address for whom deposit is being done
     * @param depositData abi encoded amount
     */
    /*function deposit(address user, bytes calldata depositData)
    external
    override
    {
        require(_depositors.contains(_msgSender()));

        uint256 amount = abi.decode(depositData, (uint256));
        _mint(user, amount);
    }*/

    /*
     * @notice called when user wants to withdraw tokens back to root chain
     * @dev Should burn user's tokens. This transaction will be verified when exiting on root chain
     * @param amount amount of tokens to withdraw
     */
    /*function withdraw(uint256 amount) external {
        _burn(_msgSender(), amount);
    }*/

    //===============

    function _msgSender()
    internal
    view
    override
    returns (address sender)
    {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
            // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
            // abi.encodePacked(functionSignature, userAddress), the lash 20 bytes is userAddress
                sender := and(
                    mload(add(array, index)),
                    0xffffffffffffffffffffffffffffffffffffffff
                )
            }
        } else {
            sender = msg.sender;
        }
        return sender;
    }
}
