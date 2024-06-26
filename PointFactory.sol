// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Point.sol";
import "./AdminControler.sol";
import "./ShareEnums.sol";
import "./IGenericContract.sol";

contract PointFactory is Ownable {
    string public constant COPYRIGHT = "Copyright (c) 2024 CarinaChain.com All rights reserved.";
    string public constant DEV = "NebulaInfinity.com";
    ContractType public constant thisContractType = ContractType.POINTFACTORY;

    AdminControler private adminControler;

    event PointCreated( 
        address indexed creationAddress,
        address indexed creator
    );

    modifier onlyPointAdmin() {
        require(adminControler.checkAdmin(msg.sender, thisContractType), "Need admin");
        _;
    }

    // owner is admin address
    constructor(address ownerAddress, address adminControlerAddress) Ownable(ownerAddress) {
        adminControler = AdminControler(adminControlerAddress);
    }

    // point transfer switch, switchon: only transfer request from point fanctory is acceptable
    function setPointTransferSwitch(
        address pointAddress, 
        bool newValue
    ) external onlyOwner {
        Point(pointAddress).setTransferSwitch(newValue); 
    }

    // change point onwer
    function changePointOwner(
        address pointAddress,
        address newOwner
    ) external onlyOwner {
        address previousOwner = Point(pointAddress).owner();
        require(newOwner != previousOwner, "Already set");
        Point(pointAddress).transferOwnership(newOwner); //check newOwner
    }

    // create point, point owner is this contract
    function createPoint(
        address creatorAddress,
        ContractType createContractType, 
        string calldata name, 
        string calldata symbol,
        uint8 decimals, 
        uint256 valueAmount,
        string calldata valueCurrency
    ) external onlyPointAdmin returns (address) {
        Point newPointContract = new Point(creatorAddress, createContractType, name, symbol, decimals, valueAmount, valueCurrency);
        emit PointCreated(address(newPointContract), creatorAddress);
        return address(newPointContract);
    }

    // distribute point with automint
    function distributePoint(
        address pointAddress,     
        address fromAddress, 
        address toAddress, 
        uint256 amount
    ) external onlyPointAdmin {
        Point(pointAddress).distribute(fromAddress, toAddress, amount);
    }

    // deduct point， burn
    function deductPoint(
        address pointAddress,     
        address senderAddress,
        address userAddress,  
        uint256 amount
    ) external onlyPointAdmin {
        Point(pointAddress).deduct(senderAddress, userAddress, amount); 
    }

    // point tranfer
    function transferPoint(
        address pointAddress,    
        address fromAddress, 
        address toAddress, 
        uint256 amount
    ) external onlyPointAdmin {
        Point(pointAddress).pTransfer(fromAddress, toAddress, amount); 
    }

    // change point distribute limit
    function changePointDistributeLimit(
        address pointAddress,
        address senderAddress,
        uint256 newValue
    ) external onlyPointAdmin {
        Point(pointAddress).changeDistributeLimit(senderAddress, newValue); 
    }

    // point transfer switch, switchon: only transfer request from point fanctory is acceptable
    function setPointMintSwitch(
        address pointAddress, 
        address senderAddress,
        bool newValue
    ) external onlyPointAdmin {
        Point(pointAddress).setMintSwitch(senderAddress, newValue); 
    }

    // change point creator 
    function changePointCreator(
        address pointAddress, 
        address senderAddress,
        address newCreator
    ) external onlyPointAdmin {
        Point(pointAddress).changeCreator(senderAddress, newCreator);
    }

}