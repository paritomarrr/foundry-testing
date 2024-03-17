// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "../src/ERC20.sol";
import "forge-std/Test.sol";

import {MockERC20} from "./mocks/MockERC20.sol";

import {TestUtils} from "./Utils/TestUtils.sol";

import {ERC20User} from "./accounts/ERC20User.sol";

contract ERC20Test is Test, TestUtils {
    bytes internal constant ARITHMETIC_ERROR =
        abi.encodeWithSignature("Panic(uint256)", 0x11);

    MockERC20 internal _token;

    function setUp() public virtual {
        _token = new MockERC20("sPHERE", "SPH", 18);
    }

    function testFuzz_metadata(
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) public {
        MockERC20 mockToken = new MockERC20(name_, symbol_, decimals_);

        assertEq(mockToken.name(), name_);
        assertEq(mockToken.symbol(), symbol_);
        assertEq(mockToken.decimals(), decimals_);
    }

    function testFuzz_mint(address account_, uint256 amount_) public {
        _token.mint(account_, amount_);

        assertEq(_token.totalSupply(), amount_);
        assertEq(_token.balanceOf(account_), amount_);
    }

    function testFuzz_burn(
        address account_,
        uint256 amount0_,
        uint256 amount1_
    ) public {
        if (amount1_ > amount0_) return;

        _token.mint(account_, amount0_);
        _token.burn(account_, amount1_);

        assertEq(_token.totalSupply(), amount0_ - amount1_);
        assertEq(_token.balanceOf(account_), amount0_ - amount1_);
    }

    function testFuzz_approve(address account_, uint256 amount_) public {
        assertTrue(_token.approve(account_, amount_));

        assertEq(_token.allowance(address(this), account_), amount_);
    }

    function testFuzz_increaseAllowance(
        address account_,
        uint256 initialAmount_,
        uint256 addedAmount_
    ) public {
        initialAmount_ = constrictToRange(
            initialAmount_,
            0,
            type(uint256).max / 2
        );
        addedAmount_ = constrictToRange(addedAmount_, 0, type(uint256).max / 2);

        _token.approve(account_, initialAmount_);

        assertEq(_token.allowance(address(this), account_), initialAmount_);

        assertTrue(_token.increaseAllowance(account_, addedAmount_));

        assertEq(
            _token.allowance(address(this), account_),
            initialAmount_ + addedAmount_
        );
    }

    function testFuzz_decreaseAllowance_infiniteApproval(
        address account_,
        uint256 subtractedAmount_
    ) public {
        uint256 MAX_UINT256 = type(uint256).max;

        subtractedAmount_ = constrictToRange(subtractedAmount_, 0, MAX_UINT256);

        _token.approve(account_, MAX_UINT256);

        assertEq(_token.allowance(address(this), account_), MAX_UINT256);

        assertTrue(_token.decreaseAllowance(account_, subtractedAmount_));

        assertEq(_token.allowance(address(this), account_), MAX_UINT256);
    }

    function testFuzz_decreaseAllowance_nonInfiniteApproval(
        address account_,
        uint256 initialAmount_,
        uint256 subtractedAmount_
    ) public {
        initialAmount_ = constrictToRange(
            initialAmount_,
            0,
            type(uint256).max - 1
        );
        subtractedAmount_ = constrictToRange(
            subtractedAmount_,
            0,
            initialAmount_
        );

        _token.approve(account_, initialAmount_);

        assertEq(_token.allowance(address(this), account_), initialAmount_);

        assertTrue(_token.decreaseAllowance(account_, subtractedAmount_));

        assertEq(
            _token.allowance(address(this), account_),
            initialAmount_ - subtractedAmount_
        );
    }

    function testFuzz_transfer(address account_, uint256 amount_) public {
        _token.mint(address(this), amount_);

        assertTrue(_token.transfer(account_, amount_));

        assertEq(_token.totalSupply(), amount_);

        if (address(this) == account_) {
            assertEq(_token.balanceOf(address(this)), amount_);
        } else {
            assertEq(_token.balanceOf(address(this)), 0);
            assertEq(_token.balanceOf(account_), amount_);
        }
    }

    function testFuzz_transferFrom(
        address recipient_,
        uint256 approval_,
        uint256 amount_
    ) public {
        approval_ = constrictToRange(approval_, 0, type(uint256).max - 1);
        amount_ = constrictToRange(amount_, 0, approval_);

        ERC20User owner = new ERC20User();

        _token.mint(address(owner), amount_);
        owner.erc20_approve(address(_token), address(this), approval_);

        assertTrue(_token.transferFrom(address(owner), recipient_, amount_));

        assertEq(_token.totalSupply(), amount_);

        approval_ = address(owner) == address(this)
            ? approval_
            : approval_ - amount_;

        assertEq(_token.allowance(address(owner), address(this)), approval_);

        if (address(owner) == recipient_) {
            assertEq(_token.balanceOf(address(owner)), amount_);
        } else {
            assertEq(_token.balanceOf(address(owner)), 0);
            assertEq(_token.balanceOf(recipient_), amount_);
        }
    }

    function testFuzz_transferFrom_infiniteApproval(
        address recipient_,
        uint256 amount_
    ) public {
        uint256 MAX_UINT256 = type(uint256).max;

        amount_ = constrictToRange(amount_, 0, MAX_UINT256);

        ERC20User owner = new ERC20User();

        _token.mint(address(owner), amount_);
        owner.erc20_approve(address(_token), address(this), MAX_UINT256);

        assertEq(_token.balanceOf(address(owner)), amount_);
        assertEq(_token.totalSupply(), amount_);
        assertEq(_token.allowance(address(owner), address(this)), MAX_UINT256);

        assertTrue(_token.transferFrom(address(owner), recipient_, amount_));

        assertEq(_token.totalSupply(), amount_);
        assertEq(_token.allowance(address(owner), address(this)), MAX_UINT256);

        if (address(owner) == recipient_) {
            assertEq(_token.balanceOf(address(owner)), amount_);
        } else {
            assertEq(_token.balanceOf(address(owner)), 0);
            assertEq(_token.balanceOf(recipient_), amount_);
        }
    }

    function testFuzz_transfer_insufficientBalance(
        address recipient_,
        uint256 amount_
    ) public {
        amount_ = amount_ == 0 ? 1 : amount_;

        ERC20User account = new ERC20User();

        _token.mint(address(account), amount_ - 1);

        vm.expectRevert(ARITHMETIC_ERROR);
        account.erc20_transfer(address(_token), recipient_, amount_);

        _token.mint(address(account), 1);
        account.erc20_transfer(address(_token), recipient_, amount_);

        assertEq(_token.balanceOf(recipient_), amount_);
    }

    function testFuzz_transferFrom_insufficientAllowance(
        address recipient_,
        uint256 amount_
    ) public {
        amount_ = amount_ == 0 ? 1 : amount_;

        ERC20User owner = new ERC20User();

        _token.mint(address(owner), amount_);

        owner.erc20_approve(address(_token), address(this), amount_ - 1);

        vm.expectRevert(ARITHMETIC_ERROR);
        _token.transferFrom(address(owner), recipient_, amount_);

        owner.erc20_approve(address(_token), address(this), amount_);
        _token.transferFrom(address(owner), recipient_, amount_);

        assertEq(_token.balanceOf(recipient_), amount_);
    }

    function testFuzz_transferFrom_insufficientBalance(
        address recipient_,
        uint256 amount_
    ) public {
        amount_ = amount_ == 0 ? 1 : amount_;

        ERC20User owner = new ERC20User();

        _token.mint(address(owner), amount_ - 1);
        owner.erc20_approve(address(_token), address(this), amount_);

        vm.expectRevert(ARITHMETIC_ERROR);
        _token.transferFrom(address(owner), recipient_, amount_);

        _token.mint(address(owner), 1);
        _token.transferFrom(address(owner), recipient_, amount_);

        assertEq(_token.balanceOf(recipient_), amount_);
    }
}
