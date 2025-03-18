//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {HelperConfig} from "./HelperConfig.s.sol";
import {LendingPool} from "../src/LendingPool.sol";
import {Script, console} from "forge-std/Script.sol";

contract DeployLendingPool is Script{

    /// @dev I have used USDC as my token.

    address token;
    address weth;
    address tokenPriceFeed;
    address wethPriceFeed;
    uint256 deployerKey;

    function run() external returns(LendingPool) {
        LendingPool pool;
        HelperConfig helper = new HelperConfig();
        token = helper.getConfig().token;
        weth = helper.getConfig().weth;
        
        tokenPriceFeed = helper.getConfig().tokenPriceFeed;
        wethPriceFeed = helper.getConfig().wethPriceFeed;
        vm.startBroadcast();
        pool = new LendingPool(token, weth, tokenPriceFeed, wethPriceFeed);
        vm.stopBroadcast();
        return pool;
    }
}