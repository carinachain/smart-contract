// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./UserManager.sol";
import "./PointFactory.sol";
import "./AdminControler.sol";
import "./IGenericContract.sol";
import "./ShareEnums.sol";

contract Router {
    string public constant COPYRIGHT = "Copyright (c) 2024 CarinaChain.com All rights reserved.";
    string public constant DEV = "NebulaInfinity.com";
    ContractType public constant thisContractType = ContractType.ROUTER;

    AdminControler private adminControler;
    PointFactory private pointFactory;
    UserManager private userManager;

    event ContractCreated(ContractType indexed contractType, address indexed newCreationAddress, address indexed creatorAddress);
    event ContractCreatorChanged(ContractType indexed contractType, address indexed creationAddress, address newCreator, address indexed previousCreator); 

    modifier onlyRouterAdmin() {
        require(adminControler.checkAdmin(msg.sender, ContractType.ROUTER), "Need admin");
        _;
    }

    modifier onlyAuthroizedUser(address contractAddress, address senderAddress) {
        bool result;
        address contractCreator = IGenericContract(contractAddress).creator();
        address senderStoreAddress = userManager.getStoreFromClerk(senderAddress);
        address senderStoreGroupAddress = userManager.getGroupFromStore(senderStoreAddress);
        address senderGroupAddress = userManager.getGroupFromStore(senderAddress);

        result = (
            contractCreator == senderStoreAddress || 
            contractCreator == senderStoreGroupAddress ||
            contractCreator == senderGroupAddress ||
            contractCreator == senderAddress || 
            uint8(userManager.getContractBERelation(contractAddress, senderStoreAddress)) > 1 ||
            uint8(userManager.getContractBERelation(contractAddress, senderStoreGroupAddress)) > 1 ||
            uint8(userManager.getContractBERelation(contractAddress, senderAddress)) > 1 ||
            uint8(userManager.getContractBERelation(contractAddress, senderGroupAddress)) > 1
        );
        require(result, "No authorization");
        _;
    }

    modifier notOverLimit(address userAddress, ContractType targetType) {
        require(userManager.getCreationAddressList(userAddress, targetType).length < adminControler.getCreationLimit(targetType), "Reached creation limit");
        _;
    }
    
    // owner is server    
    constructor (address adminControlerAddress) {
        require(adminControlerAddress != address(0), "Invalid address");
        adminControler = AdminControler(adminControlerAddress);
        pointFactory = PointFactory(adminControler.getContractAddress(ContractType.POINTFACTORY));
        userManager = UserManager(adminControler.getContractAddress(ContractType.USERMANAGER));
    }

    // pay credit to contract owner as fee
    function _payFee(address payerAddress, uint256 feeAmount) internal {
        require(uint8(userManager.getUserType(payerAddress)) > 1, "Only for registered user");
        pointFactory.transferPoint(adminControler.getContractAddress(ContractType.CREDITPOINT), payerAddress, address(this), feeAmount);
    }

    // contract owner, Group or sender pay fee
    function _payUsingFee(address contractAddress, address senderAddress, uint256 feeAmount) internal {
        address payerAddress = senderAddress;
        address contractCreator = IGenericContract(contractAddress).creator();
        address senderStoreAddress = userManager.getStoreFromClerk(senderAddress);
        address senderStoreGroupAddress = userManager.getGroupFromStore(senderStoreAddress);
        address senderGroupAddress = userManager.getGroupFromStore(senderAddress);

        if(
            userManager.getStoreGroupRelation(senderStoreAddress, contractCreator) == RelationType.FEEFREE ||
            userManager.getContractBERelation(contractAddress, senderStoreAddress) == RelationType.FEEFREE ||
            userManager.getContractBERelation(contractAddress, senderStoreGroupAddress) == RelationType.FEEFREE ||
            userManager.getStoreGroupRelation(senderAddress, contractCreator) == RelationType.FEEFREE ||
            userManager.getContractBERelation(contractAddress, senderGroupAddress) == RelationType.FEEFREE ||
            userManager.getContractBERelation(contractAddress, senderAddress) == RelationType.FEEFREE
        ){
            payerAddress = contractCreator;
        } else if(
            userManager.getContractBERelation(contractAddress, senderStoreGroupAddress) == RelationType.FEESELFPAY &&
            userManager.getStoreGroupRelation(senderStoreAddress, senderStoreGroupAddress) == RelationType.FEEFREE
        ){
            payerAddress = senderStoreGroupAddress;
        } else if(
            userManager.getContractBERelation(contractAddress, senderGroupAddress) == RelationType.FEESELFPAY &&
            userManager.getStoreGroupRelation(senderAddress, senderGroupAddress) == RelationType.FEEFREE
        ){
            payerAddress = senderGroupAddress;
        }

        _payFee(payerAddress, feeAmount);
    }

    function _paySettingFee(address senderAddress, uint256 feeAmount) internal {
        address payerAddress = senderAddress;
        address senderGroupAddress = userManager.getGroupFromStore(senderAddress);
        if(userManager.getStoreGroupRelation(senderAddress, senderGroupAddress) == RelationType.FEEFREE){
            payerAddress = senderGroupAddress;
        }
        _payFee(payerAddress, feeAmount);
    }

    // creation
    function createInFactory(
        address creatorAddress,  
        ContractType targetType, 
        string calldata name, 
        string calldata symbol, 
        uint8 decimals,
        // TokenValue calldata tokenValue,
        uint256 feeAmount
    ) external onlyRouterAdmin notOverLimit(creatorAddress, targetType) {
        _payFee(creatorAddress, feeAmount);
        address newCreationAddress;

        if(targetType == ContractType.POINT){
            require(userManager.getUserType(creatorAddress) == UserType.STORE || userManager.getUserType(creatorAddress) == UserType.GROUP, "Creator must be Group/Store");
            newCreationAddress = pointFactory.createPoint(creatorAddress, targetType, name, symbol, decimals);
        } else {
            revert("Unavailable type");
        }

        userManager.addToCreationList(newCreationAddress);
        emit ContractCreated(targetType, newCreationAddress, creatorAddress);
    }

    // distribute
    function distribution(
        address contractAddress, 
        address senderAddress, 
        address userAddress, 
        uint256 amount,
        uint256 feeAmount
    ) external onlyRouterAdmin onlyAuthroizedUser(contractAddress, senderAddress) { 
        _payUsingFee(contractAddress, senderAddress, feeAmount);

        if(IGenericContract(contractAddress).owner() == adminControler.getContractAddress(ContractType.POINTFACTORY)){
            pointFactory.distributePoint(contractAddress, senderAddress, userAddress, amount);
        } else {
            revert("Contract type not support");
        }
    }

    // sender take creation from user
    function deduction(
        address contractAddress, 
        address senderAddress, 
        address userAddress, 
        uint256 amount,
        uint256 feeAmount
    ) external onlyRouterAdmin onlyAuthroizedUser(contractAddress, senderAddress) {
        _payUsingFee(contractAddress, senderAddress, feeAmount);

        if(IGenericContract(contractAddress).owner() == adminControler.getContractAddress(ContractType.POINTFACTORY)){
            pointFactory.deductPoint(contractAddress, senderAddress, userAddress, amount);
        } else {
            revert("Contract type not support");
        }
    }

    // creation transfer, from address pay fee
    function contractTransfer(
        address contractAddress, 
        address fromAddress, 
        address toAddress, 
        uint256 amount,
        uint256 feeAmount
    ) external onlyRouterAdmin {
        _payFee(fromAddress, feeAmount);

        if(IGenericContract(contractAddress).owner() == adminControler.getContractAddress(ContractType.POINTFACTORY)){
            pointFactory.transferPoint(contractAddress, fromAddress, toAddress, amount);
        } else {
            revert("Contract type not support");
        }
    }

    // change contract distribute limit
    function changeContractDistributeLimit(
        address contractAddress, 
        address senderAddress, 
        uint256 newValue,
        uint256 feeAmount
    ) external onlyRouterAdmin {
        _payFee(senderAddress, feeAmount);

        if(IGenericContract(contractAddress).owner() == adminControler.getContractAddress(ContractType.POINTFACTORY)){
            pointFactory.changePointDistributeLimit(contractAddress, senderAddress, newValue);
        } else {
            revert("Contract type not support");
        }
    }

    // change creation creator， not over the creation limit
    function changeContractCreator(
        address contractAddress,
        address senderAddress,
        address newCreator,
        uint256 feeAmount
    ) external onlyRouterAdmin notOverLimit(newCreator, IGenericContract(contractAddress).thisContractType()) {
        ContractType creationType = IGenericContract(contractAddress).thisContractType();
        address previousCreator = IGenericContract(contractAddress).creator();
        userManager.removeFromCreationList(contractAddress);

        _payFee(senderAddress, feeAmount);

        if(IGenericContract(contractAddress).owner() == adminControler.getContractAddress(ContractType.POINTFACTORY)){
            require(userManager.getUserType(newCreator) == UserType.STORE  || userManager.getUserType(newCreator) == UserType.GROUP, "Creator must be Group/Store");
            pointFactory.changePointCreator(senderAddress, contractAddress, newCreator);
        } else {
            revert("Contract type not support");
        }
        
        userManager.addToCreationList(contractAddress);
        emit ContractCreatorChanged(creationType, contractAddress, newCreator, previousCreator);
    }

    function manageUserRegistration(
        address userAddress,
        UserType userType,
        uint256 feeAmount
    ) external onlyRouterAdmin {
        pointFactory.transferPoint(adminControler.getContractAddress(ContractType.CREDITPOINT), userAddress, address(this), feeAmount);
        userManager.manageUser(userAddress, userType);
    }

    function manageGroupStore(
        address groupAddress, 
        address storeAddress,
        RelationType relationType,
        uint256 feeAmount
    ) external onlyRouterAdmin {
        _payFee(groupAddress, feeAmount);
        userManager.manageGroupStoreRelation(groupAddress, storeAddress, relationType);
    }

    function manageContractBE(
        address senderAddress,
        address contractAddress,
        address businessEntityAddress,
        RelationType targetType,
        uint256 feeAmount
    ) external onlyRouterAdmin {
        _paySettingFee(senderAddress, feeAmount);
        userManager.manageContractBE(senderAddress, contractAddress, businessEntityAddress, targetType);
    }

    function addClerkToList(
        address storeAddress,
        address clerkAddress,
        uint256 feeAmount
    ) external onlyRouterAdmin {
        _paySettingFee(storeAddress, feeAmount);
        userManager.addClerk(storeAddress, clerkAddress);
    }

    function removeClerkFromList(
        address storeAddress,
        address removeClerkAddress,
        uint256 feeAmount
    ) external onlyRouterAdmin {
        _paySettingFee(storeAddress, feeAmount);
        userManager.removeClerk(storeAddress, removeClerkAddress);
    }

}