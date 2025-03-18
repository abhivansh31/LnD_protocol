//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

// import {Test} from "forge-std/Test.sol";
// import {LendingPool} from "../../src/LendingPool.sol";
// import {HelperConfig} from "../../script/HelperConfig.s.sol";
// import {DeployLendingPool} from "../../script/DeployLendingPool.s.sol";
// import {Handler} from "./Handler.t.sol";

// contract InvariantsTest is Test {
//     address token;
//     address weth;
//     address tokenPriceFeed;
//     address wethPriceFeed;
//     Handler handler;
//     LendingPool pool;
//     DeployLendingPool deployer;
//     HelperConfig helper;
//     uint256 constant AMOUNT = 100 * 10 ** 18;
//     uint256 constant funds = 10 * 10 ** 18;

//     function setUp() external {
//         helper = new HelperConfig();
//         deployer = new DeployLendingPool();
//         token = helper.getConfig().token;
//         weth = helper.getConfig().weth;
//         tokenPriceFeed = helper.getConfig().tokenPriceFeed;
//         wethPriceFeed = helper.getConfig().wethPriceFeed;
//         pool = deployer.run();
//         handler = new Handler(pool, token, weth);
//         deal(token, address(handler), AMOUNT);
//         deal(weth, address(handler), AMOUNT);
//         targetContract(address(handler));
//     }

//     function invariant_CollateralIsMoreThanBorrowedAmount() public {
//         handler.addLiquidity(AMOUNT);
//         handler.removeLiquidity();
//         uint256 borrowedAmount = pool.getBorrowedAmount();
//         uint256 collateral = pool.getDepositedCollateral();
//         assert(collateral >= borrowedAmount);
//     }
// }