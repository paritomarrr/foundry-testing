pragma solidity 0.8.7;

import "../mocks/MockERC20.sol";

contract BalanceSum {

    MockERC20 public token = new MockERC20("Token", "TKN", 18);

    uint256 public sum;

    function mint(address recipient_, uint256 amount_) public {
        token.mint(recipient_, amount_);
        sum += amount_;
    }

    function burn(address owner_, uint256 amount_) public {
        token.burn(owner_, amount_);
        sum -= amount_;
    }

    function approve(address spender_, uint256 amount_) public {
        token.approve(spender_, amount_);
    }

    function transferFrom(address owner_, address recipient_, uint256 amount_) public {
        token.transferFrom(owner_, recipient_, amount_);
    }

    function transfer(address recipient_, uint256 amount_) public {
        token.transfer(recipient_, amount_);
    }

}
