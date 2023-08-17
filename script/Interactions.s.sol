// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.18;
import {Script,console} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import {LinkToken} from "../test/mocks/LinkToken.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";
contract CreateSubscription is Script{

    function createSubscriptionUsingConfig() public returns(uint64){
        HelperConfig helperConfig = new HelperConfig();
        (uint256 entranceFee,
            uint256 interval,
            address vrfCoordinator,
            bytes32 gasLane,
            uint64 subscriptionId,
            uint32 callbackGasLimit,address link,uint256 deployerKey)= helperConfig.activeNetworkConfig();
        return createSubscription(vrfCoordinator,deployerKey);
    }
    function createSubscription(address vrfCoordinator,uint256 deployerKey) public returns(uint64){
        console.log("creating subscription on chainid",block.chainid);
        vm.startBroadcast(deployerKey);
        uint64 subId = VRFCoordinatorV2Mock(vrfCoordinator).createSubscription();
        vm.stopBroadcast();
        console.log("subid is ",subId);
        return subId;
    }

    function run() external returns(uint64){
        return createSubscriptionUsingConfig();
    }
}

contract FundSubscription is Script{
    uint96 public constant FUND_AMOUNT = 3 ether;

    function fundSubscriptionUsingConfig() public{
        HelperConfig helperConfig = new HelperConfig();
        (uint256 entranceFee,
            uint256 interval,
            address vrfCoordinator,
            bytes32 gasLane,
            uint64 subscriptionId,
            uint32 callbackGasLimit,address link,uint256 deployerKey)= helperConfig.activeNetworkConfig();
        fundSubscription(vrfCoordinator,subscriptionId,link,deployerKey);
    }
    function fundSubscription(address vrfCoordinator, uint64 subId, address link, uint256 deployerKey) public{
        console.log("Funding Subscription", subId);
        console.log("vrfcoordinator",vrfCoordinator);
        console.log("Chain id",block.chainid);
        if (block.chainid==31337) {
            vm.startBroadcast(deployerKey);
            VRFCoordinatorV2Mock(vrfCoordinator).fundSubscription(subId,FUND_AMOUNT);
            vm.stopBroadcast();
        }
        else{
            vm.startBroadcast(deployerKey);
            LinkToken(link).transferAndCall(vrfCoordinator,FUND_AMOUNT,abi.encode(subId));
            vm.stopBroadcast();
        }
    }
    function run() external {
        fundSubscriptionUsingConfig();
    }
}

contract AddConsumer is Script {
    function addConsumer(address raffle,address vrfCoordinator, uint64 subId,uint256 deployerKey) public{
        console.log("adding consumer contract", raffle);
        console.log("using vrfCoordinator", vrfCoordinator);
        console.log("chain id: ", block.chainid);


        vm.startBroadcast(deployerKey);
        VRFCoordinatorV2Mock(vrfCoordinator).addConsumer(subId,raffle);
        vm.stopBroadcast();
    }
    function addConsumerUsingConfig(address raffle) public{
        HelperConfig helperConfig = new HelperConfig();
        (uint256 entranceFee,
            uint256 interval,
            address vrfCoordinator,
            bytes32 gasLane,
            uint64 subscriptionId,
            uint32 callbackGasLimit,address link,uint256 deployerKey)= helperConfig.activeNetworkConfig();
            addConsumer(raffle,vrfCoordinator,subscriptionId,deployerKey);

    }
    function run() external {
        address raffleAddress = DevOpsTools.get_most_recent_deployment("Raffle", block.chainid);
        addConsumerUsingConfig(raffleAddress);
    }
}