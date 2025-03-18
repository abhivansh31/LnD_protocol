//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";
import {LendingPool} from "../src/LendingPool.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";
import {DeployLendingPool} from "../script/DeployLendingPool.s.sol";
import {ERC20Mock} from "../lib/openzeppelin-contracts/contracts/mocks/token/ERC20Mock.sol";

contract LendingPoolTest is Test {
    LendingPool pool;
    HelperConfig helper;
    DeployLendingPool deployer;
    address token;
    address weth;
    address tokenPriceFeed;
    address wethPriceFeed;
    uint256 constant AMOUNT = 100 * 10 ** 18;

    function setUp() external {
        helper = new HelperConfig();
        deployer = new DeployLendingPool();
        token = helper.getConfig().token;
        weth = helper.getConfig().weth;
        tokenPriceFeed = helper.getConfig().tokenPriceFeed;
        wethPriceFeed = helper.getConfig().wethPriceFeed;
        pool = deployer.run();
        ERC20Mock(token).mint( address(this), AMOUNT);
        ERC20Mock(weth).mint(address(this), AMOUNT);
    }

    function test_DepositCollateral() public {
        ERC20Mock(weth).approve(address(pool), AMOUNT);
        pool.depositCollateralAndBorrowToken(AMOUNT, 0);
        assertEq(pool.getDepositedCollateral(), AMOUNT);
    }

    function test_BorrowToken() public {
        ERC20Mock(weth).approve(address(pool), AMOUNT);
        uint256 borrowAmount = AMOUNT / 2;
        pool.depositCollateralAndBorrowToken(AMOUNT, borrowAmount);
        assertEq(pool.getBorrowedAmount(), borrowAmount);
    }

    function test_AddLiquidity() public {
        ERC20Mock(token).approve(address(pool), AMOUNT);
        pool.addLiquidity(AMOUNT);
        assertEq(pool.balanceOf(address(this)), AMOUNT);
    }

    function test_RemoveLiquidity() public {
        ERC20Mock(token).approve(address(pool), AMOUNT);
        pool.addLiquidity(AMOUNT);
        uint256 balanceBefore = ERC20Mock(token).balanceOf(address(this));
        pool.removeLiquidity();
        uint256 balanceAfter = ERC20Mock(token).balanceOf(address(this));
        assertGt(balanceAfter, balanceBefore);
    }

    function test_Liquidation() public {
        address user = makeAddr("user");
        deal(weth, user, AMOUNT);
        deal(token, address(this), AMOUNT);
        
        vm.startPrank(user);
        ERC20Mock(weth).approve(address(pool), AMOUNT);
        pool.depositCollateralAndBorrowToken(AMOUNT, AMOUNT/2);
        vm.stopPrank();
        
        ERC20Mock(token).approve(address(pool), AMOUNT);
        pool.liquidate(user, address(this));
        uint256 collateralDeposited = pool.getDepositedCollateral();
        assertEq(collateralDeposited, 0);
    }

    function test_HealthFactor() public {
        ERC20Mock(weth).approve(address(pool), AMOUNT);
        pool.depositCollateralAndBorrowToken(AMOUNT, AMOUNT/3);
        assertTrue(pool.checkIfHealthFactorIsOkay(address(this)));
    }
}