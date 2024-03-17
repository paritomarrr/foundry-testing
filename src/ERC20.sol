// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.7;

import {IERC20} from "./interfaces/IERC20.sol";

/**
 *  @title ERC-20 implementation.
 */

contract ERC20 is IERC20 {
    ////////////////////////////////////////////////////////////
    //                        VARIABLES                       //
    ////////////////////////////////////////////////////////////

    string public override name;
    string public override symbol;

    uint8 public immutable override decimals;

    uint256 public override totalSupply;

    mapping(address => uint256) public override balanceOf;

    mapping(address => mapping(address => uint256)) public override allowance;

    // PERMIT_TYPEHASH = keccak256("Permit(address owner, address spender, uint256 value, uint256 nonce, uint256 deadline)");
    bytes32 public constant override PERMIT_TYPEHASH =
        0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

    mapping(address => uint256) public override nonces;

    ////////////////////////////////////////////////////////////
    //                      CONSTRUCTOR                       //
    ////////////////////////////////////////////////////////////

    /**
     *  @param name_     The name of the token.
     *  @param symbol_   The symbol of the token.
     *  @param decimals_ The decimal precision used by the token.
     */
    constructor(string memory name_, string memory symbol_, uint8 decimals_) {
        name = name_;
        symbol = symbol_;
        decimals = decimals_;
    }

    ////////////////////////////////////////////////////////////
    //                   EXTERNAL FUNCTION                    //
    ////////////////////////////////////////////////////////////

    function approve(
        address spender_,
        uint256 amount_
    ) public virtual override returns (bool success_) {
        _approve(msg.sender, spender_, amount_);
        return true;
    }

    function decreaseAllowance(
        address spender_,
        uint256 subtractedAmount_
    ) public virtual override returns (bool success_) {
        _decreaseAllowance(msg.sender, spender_, subtractedAmount_);
        return true;
    }

    function increaseAllowance(
        address spender_,
        uint256 addedAmount_
    ) public virtual override returns (bool success_) {
        _approve(
            msg.sender,
            spender_,
            allowance[msg.sender][spender_] + addedAmount_
        );
        return true;
    }

    function permit(
        address owner_,
        address spender_,
        uint256 amount_,
        uint256 deadline_,
        uint8 v_,
        bytes32 r_,
        bytes32 s_
    ) public virtual override {
        require(deadline_ >= block.timestamp, "ERC20:P:EXPIRED");

        require(
            uint256(s_) <=
                uint256(
                    0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0
                ) &&
                (v_ == 27 || v_ == 28),
            "ERC20:P:MALLEABLE"
        );

        unchecked {
            bytes32 digest_ = keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR(),
                    keccak256(
                        abi.encode(
                            PERMIT_TYPEHASH,
                            owner_,
                            spender_,
                            amount_,
                            nonces[owner_]++,
                            deadline_
                        )
                    )
                )
            );

            address recoveredAddress_ = ecrecover(digest_, v_, r_, s_);

            require(
                recoveredAddress_ == owner_ && owner_ != address(0),
                "ERC20:P:INVALID_SIGNATURE"
            );
        }

        _approve(owner_, spender_, amount_);
    }

    function transfer(
        address recipient_,
        uint256 amount_
    ) public virtual override returns (bool success_) {
        _transfer(msg.sender, recipient_, amount_);
        return true;
    }

    function transferFrom(
        address owner_,
        address recipient_,
        uint256 amount_
    ) public virtual override returns (bool success_) {
        _decreaseAllowance(owner_, msg.sender, amount_);
        _transfer(owner_, recipient_, amount_);
        return true;
    }

    function DOMAIN_SEPARATOR()
        public
        view
        override
        returns (bytes32 domainSeparator_)
    {
        return
            keccak256(
                abi.encode(
                    keccak256(
                        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                    ),
                    keccak256(bytes(name)),
                    keccak256(bytes("1")),
                    block.chainid,
                    address(this)
                )
            );
    }

    ////////////////////////////////////////////////////////////
    //                  INTERNAL FUNCTIONS                    //
    ////////////////////////////////////////////////////////////

    function _approve(
        address owner_,
        address spender_,
        uint256 amount_
    ) internal {
        emit Approval(owner_, spender_, allowance[owner_][spender_] = amount_);
    }

    function _burn(address owner_, uint256 amount_) internal {
        balanceOf[owner_] -= amount_;

        unchecked {
            totalSupply -= amount_;
        }

        emit Transfer(owner_, address(0), amount_);
    }

    function _decreaseAllowance(
        address owner_,
        address spender_,
        uint256 subtractedAmount_
    ) internal {
        uint256 spenderAllowance = allowance[owner_][spender_]; 

        if (spenderAllowance != type(uint256).max) {
            _approve(owner_, spender_, spenderAllowance - subtractedAmount_);
        }
    }

    function _mint(address recipient_, uint256 amount_) internal {
        totalSupply += amount_;

        unchecked {
            balanceOf[recipient_] += amount_;
        }

        emit Transfer(address(0), recipient_, amount_);
    }

    function _transfer(
        address owner_,
        address recipient_,
        uint256 amount_
    ) internal {
        balanceOf[owner_] -= amount_;

        unchecked {
            balanceOf[recipient_] += amount_;
        }

        emit Transfer(owner_, recipient_, amount_);
    }
}
