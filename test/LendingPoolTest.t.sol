//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {LendingPool} from "../src/LendingPool.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";
import {DeployLendingPool} from "../script/DeployLendingPool.s.sol";
import {ERC20Mock} from "../lib/openzeppelin-contracts/contracts/mocks/token/ERC20Mock.sol";
import {IERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract LendingPoolTest is Test {
    LendingPool pool;
    HelperConfig helper;
    DeployLendingPool deployer;
    address token;
    address weth;
    address tokenPriceFeed;
    address wethPriceFeed;
    uint256 constant AMOUNT = 100 * 10 ** 18;
    uint256 constant funds = 10 * 10 ** 18;

    function setUp() external {
        helper = new HelperConfig();
        deployer = new DeployLendingPool();
        token = helper.getConfig().token;
        weth = helper.getConfig().weth;
        console.log(weth);
        console.log(token);
        tokenPriceFeed = helper.getConfig().tokenPriceFeed;
        wethPriceFeed = helper.getConfig().wethPriceFeed;
        pool = deployer.run();
        console.log(address(pool));
        ERC20Mock(weth).mint(address(this), AMOUNT);
        ERC20Mock(token).mint(address(this), AMOUNT);
        console.log(address(this));
        console.log(IERC20(token).balanceOf(address(this)));
        console.log(IERC20(weth).balanceOf(address(this)));
        ERC20Mock(weth).approve(address(pool), AMOUNT);
        ERC20Mock(token).approve(address(pool), AMOUNT);
        console.log(IERC20(weth).allowance(address(this), address(pool)));
        console.log(IERC20(token).allowance(address(this), address(pool)));
    }

    function testFuzzDepositCollateral(uint256 amount) public {
        amount = bound(amount, 10 ether, 50 ether);
        ERC20Mock(weth).approve(address(pool), amount);
        console.log(amount);
        console.log(IERC20(weth).balanceOf(address(this)));
        console.log(IERC20(weth).allowance(address(this), address(pool)));
        
        pool.depositCollateralAndBorrowToken(amount, amount/3);
        assert(pool.getDepositedCollateral() == amount);

    }
    
}