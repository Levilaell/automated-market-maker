// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import {AMM} from "../src/AMM.sol";

contract DeployAMM is Script {
    // tokens reais na Sepolia
    address constant WETH = 0x7b79995e5f793A07Bc00c21412e50Ecae098E7f9;
    address constant USDC = 0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238;

    function run() external {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        new AMM(WETH, USDC);
        vm.stopBroadcast();
    }
}
