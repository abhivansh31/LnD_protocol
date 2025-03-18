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
    address user = makeAddr("user");
    uint256 constant AMOUNT = 100 * 10 ** 18;
    uint256 constant funds = 10 * 10 ** 18;

    function setUp() external {
        helper = new HelperConfig();
        deployer = new DeployLendingPool();
        token = helper.getConfig().token;
        weth = helper.getConfig().weth;
        pool = deployer.run();
        ERC20Mock(weth).mint(user, AMOUNT);
        ERC20Mock(token).mint(user, AMOUNT);
        ERC20Mock(weth).mint(address(pool), AMOUNT);
        ERC20Mock(token).mint(address(pool), AMOUNT);
    }

    function testAddLiquidity(uint256 amount) public{
        amount = bound(amount, 0, funds/2);
        vm.startPrank(user);
        IERC20(weth).approve(address(pool), amount);
        pool.addLiquidity(amount);
        vm.stopPrank();
        assert(pool.getLPTokens(user) > 0);
    } 
}