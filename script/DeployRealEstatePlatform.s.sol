// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Script} from "forge-std/Script.sol";
import {RealEstatePlatform} from "src/RealEstatePlatform.sol";

contract DeployRealEstatePlatform is Script {
    function run() external {
        vm.startBroadcast();
        RealEstatePlatform realEstatePlatform = new RealEstatePlatform();
        vm.stopBroadcast();
    }
}
 