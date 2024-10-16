// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Point.sol";
import "./AdminControler.sol";
import "./ShareEnums.sol";

contract PointFactory is Ownable {
    string public constant COPYRIGHT = "Copyright (c) 2024 CarinaChain.com All rights reserved.";
    string public constant DEV = "NebulaInfinity.com";
    ContractType public constant thisContractType = ContractType.POINTFACTORY;

    AdminControler private adminControler;

    mapping(address => uint256) private distributeLimit;

    event PointCreated(address indexed pointAddress, address indexed creator);
    event PointDistributeLimitChanged(address indexed pointAddress, uint256 indexed previousValue, uint256 indexed newValue);

    modifier onlyPointFactoryAdmin() {
        require(adminControler.checkAdmin(msg.sender, thisContractType), "Need PointFactoryAdmin");
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
        require(newOwner != previousOwner, "newOwner is same as now");
        Point(pointAddress).transferOwnership(newOwner); 
    }

    // create point, point owner is this contract
    function createPoint(
        address creatorAddress,
        ContractType createContractType, 
        string calldata name, 
        string calldata symbol,
        uint8 decimals
    ) external onlyPointFactoryAdmin returns (address) {
        Point newPointContract = new Point(creatorAddress, createContractType, name, symbol, decimals);
        distributeLimit[address(newPointContract)] = 100000 * (10 ** uint256(decimals));
        emit PointCreated(address(newPointContract), creatorAddress);
        return address(newPointContract);
    }

    function getDistributeLimit(address pointAddress) external view returns(uint256) {
        return distributeLimit[pointAddress];
    }

    function changePointDistributeLimit(
        address pointAddress,
        uint256 newValue
    ) external onlyPointFactoryAdmin {
        uint256 previousValue = distributeLimit[pointAddress];
        require(newValue != previousValue, "newValue is same as now");
        distributeLimit[pointAddress] = newValue;
        emit PointDistributeLimitChanged(pointAddress, previousValue, newValue);
    }

    // distribute point with automint
    function distributePoint(
        address pointAddress,     
        address fromAddress, 
        address toAddress, 
        uint256 amount
    ) external onlyPointFactoryAdmin {
        require(amount <= distributeLimit[pointAddress], "amount over the distribution limit");
        Point(pointAddress).distribute(fromAddress, toAddress, amount);
    }

    // deduct point， burn
    function deductPoint(
        address pointAddress,     
        address senderAddress,
        address userAddress,  
        uint256 amount
    ) external onlyPointFactoryAdmin {
        Point(pointAddress).deduct(senderAddress, userAddress, amount); 
    }

    // point tranfer
    function transferPoint(
        address pointAddress,    
        address fromAddress, 
        address toAddress, 
        uint256 amount
    ) external onlyPointFactoryAdmin {
        Point(pointAddress).pTransfer(fromAddress, toAddress, amount); 
    }

    // change point creator 
    function changePointCreator(
        address pointAddress, 
        address senderAddress,
        address newCreator
    ) external onlyPointFactoryAdmin {
        Point(pointAddress).changeCreator(senderAddress, newCreator);
    }

    // point paused status, default is false
    function setPointPauseStatus(
        address pointAddress, 
        address senderAddress,
        bool newValue
    ) external onlyPointFactoryAdmin {
        Point(pointAddress).changePauseStatus(senderAddress, newValue); 
    }

}