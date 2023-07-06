// SPDX-License-Identifier: MIT

// Deploy mocks when we're on anvil local chain
// Keep track of contract addresses across different chains
// Sepolia ETH/USD contract address = A
// Mainnet ETH/USD contract address = B

pragma solidity 0.8.19;

import {Script} from "forge-std/Script.sol";
import {MockV3Aggregator} from "../test/mocks/MockV3Aggregator.sol";

contract HelperConfig is Script {
    NetworkConfig public activeNetworkConfig;

    uint8 public constant DECIMALS = 8;
    int256 public constant INTIAL_PRICE = 1000e8;
    uint256 public constant SEPOLIA_CHAIN_ID = 11155111;
    uint256 public constant ARBITRUM_CHAIN_ID = 42161;

    // If using local Anvil testnet: utilize mock contracts
    // If using public Testnets/Mainnet: grab real addresses

    // This state variable will allow other contracts (script) to access the current NetworkConfig
    struct NetworkConfig {
        address priceFeed; // ETH/USD pricefeed
    }

    constructor() {
        if (block.chainid == SEPOLIA_CHAIN_ID) {
            activeNetworkConfig = getSepoliaEthConfig();
        } else if (block.chainid == ARBITRUM_CHAIN_ID) {
            activeNetworkConfig = getArbitrumEthConfig();
        } else {
            activeNetworkConfig = getOrCreateAnvilEthConfig();
        }
    }

    function getSepoliaEthConfig() public pure returns (NetworkConfig memory) {
        // price feed address
        NetworkConfig memory sepoliaConfig = NetworkConfig(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        return sepoliaConfig;
    }

    function getArbitrumEthConfig() public pure returns (NetworkConfig memory) {
        // price feed address
        NetworkConfig memory arbitrumConfig = NetworkConfig(0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612);
        return arbitrumConfig;
    }

    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
        if (activeNetworkConfig.priceFeed != address(0)) {
            return activeNetworkConfig;
        }
        // price feed address

        // 1. Deploy mock contracts
        // 2. Return mock contract addresses

        vm.startBroadcast();
        MockV3Aggregator mockPriceFeed = new MockV3Aggregator(
            DECIMALS,
            INTIAL_PRICE
        );
        vm.stopBroadcast();

        NetworkConfig memory anvilConfig = NetworkConfig({priceFeed: address(mockPriceFeed)});
        return anvilConfig;
    }
}
