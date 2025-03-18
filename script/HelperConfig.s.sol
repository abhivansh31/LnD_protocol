//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {MockV3Aggregator} from "../test/mocks/MockV3Aggregator.sol";
import {Script} from "forge-std/Script.sol";
import {ERC20Mock} from "../lib/openzeppelin-contracts/contracts/mocks/token/ERC20Mock.sol";

contract HelperConfig is Script {
    struct NetworkConfig {
        address token;
        address weth;
        address tokenPriceFeed;
        address wethPriceFeed;
        uint256 deployerKey;
    }

    error HelperConfig_UnsupportedChainId();

    NetworkConfig public networkConfig;

    uint256 public constant DECIMALS = 8;
    uint256 public constant WETH_PRICE = 3000e8;
    uint256 public constant USDC_PRICE = 1e8;
    uint256 private DEFAULT_ANVIL_PRIVATE_KEY = vm.envUint("ANVIL_PRIVATE_KEY"); 
    uint256 private DEFAULT_PRIVATE_KEY = vm.envUint("DEPLOYER_PRIVATE_KEY");
    uint256 constant INITIAL_BALANCE = 1000 * 10**18;

    function getConfig() public returns (NetworkConfig memory) {
        return getOrCreateConfig(block.chainid);
    }

    function getOrCreateConfig(
        uint256 chainId
    ) internal returns (NetworkConfig memory) {
        if (chainId == 11155111) {
            return getSepoliaEthConfig();
        } else if (chainId == 31337) {
            return getAnvilEthConfig();
        } else {
            revert HelperConfig_UnsupportedChainId();
        }
    }

    function getSepoliaEthConfig()
        internal
        view
        returns (NetworkConfig memory)
    {
        return
            NetworkConfig({
                token: 0xf08A50178dfcDe18524640EA6618a1f965821715,
                weth: 0xdd13E55209Fd76AfE204dBda4007C227904f0a81,
                tokenPriceFeed: 0xA2F78ab2355fe2f984D808B5CeE7FD0A93D5270E,
                wethPriceFeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306,
                deployerKey: DEFAULT_PRIVATE_KEY
            });
    }

    function getAnvilEthConfig()
        internal
        returns (NetworkConfig memory config)
    {
        if (networkConfig.wethPriceFeed != address(0)) {
            return networkConfig;
        }

        vm.startBroadcast();
        ERC20Mock token = new ERC20Mock();
        ERC20Mock weth = new ERC20Mock();
        // token.mint(address(this), INITIAL_BALANCE);
        // weth.mint(address(this), INITIAL_BALANCE);
        MockV3Aggregator tokenPriceFeed = new MockV3Aggregator(
            DECIMALS,
            USDC_PRICE
        );
        MockV3Aggregator wethPriceFeed = new MockV3Aggregator(
            DECIMALS,
            WETH_PRICE
        );
        vm.stopBroadcast();

        config = NetworkConfig({
            token: address(token),
            weth: address(weth),
            tokenPriceFeed: address(tokenPriceFeed),
            wethPriceFeed: address(wethPriceFeed),
            deployerKey: DEFAULT_ANVIL_PRIVATE_KEY
        });
        networkConfig = config;
        return config;
    }
}
