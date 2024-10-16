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

    modifier onlyRouterAdmin() {
        require(adminControler.checkAdmin(msg.sender, ContractType.ROUTER), "Need RouterAdmin");
        _;
    }
    

    constructor (address adminControlerAddress) {
        require(adminControlerAddress != address(0), "Invalid address");
        adminControler = AdminControler(adminControlerAddress);
        pointFactory = PointFactory(adminControler.getContractAddress(ContractType.POINTFACTORY));
        userManager = UserManager(adminControler.getContractAddress(ContractType.USERMANAGER));
    }


    // pay credit to contract as fee
    function _payFee(
        address payerAddress, 
        string memory functionName
    ) internal returns (uint256){
        uint256 feeAmount = adminControler.getFunctionExpense(address(this), functionName);
        address creditContractAddress = adminControler.getContractAddress(ContractType.CREDITPOINT);
        if(feeAmount > 0) {
            pointFactory.transferPoint(creditContractAddress, payerAddress, address(this), feeAmount);
        }
        return feeAmount;
    }

    function _getFeePayer(
        address contractAddress, 
        address senderAddress
    ) internal view returns (address) {
        address payerAddress = senderAddress;
        address contractCreator = IGenericContract(contractAddress).creator();
        address senderGroupAddress = userManager.getGroupFromStore(senderAddress);

        if(
            userManager.getStoreGroupRelation(senderAddress, contractCreator) == RelationType.FEEFREE ||
            userManager.getContractBERelation(contractAddress, senderGroupAddress) == RelationType.FEEFREE ||
            userManager.getContractBERelation(contractAddress, senderAddress) == RelationType.FEEFREE
        ){
            payerAddress = contractCreator;
        } else if(
            userManager.getContractBERelation(contractAddress, senderGroupAddress) == RelationType.FEESELFPAY &&
            userManager.getStoreGroupRelation(senderAddress, senderGroupAddress) == RelationType.FEEFREE
        ){
            payerAddress = senderGroupAddress;
        }

        return payerAddress;
    }

    function getFeePayer(
        address contractAddress, 
        address senderAddress
    ) external view returns (address) {
        require(_isOriginalContract(contractAddress), "contractAddress is not carina original contract");
        return _getFeePayer(contractAddress, senderAddress);
    }

    function _isInsufficientCredit(
        address targetAddress, 
        string memory functionName
    ) internal view returns (bool) {
        return adminControler.isInsufficientCredit(targetAddress, address(this), functionName);
    }

    function _isOriginalContract(address targetAddress) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(targetAddress) }
        if (size == 0) {
            return false;
        }
        try IGenericContract(targetAddress).thisContractType() returns (ContractType) {
            return true;
        } catch {
            return false;
        }
    }

    function _isContractPermittedSender(
        address contractAddress, 
        address senderAddress
    ) internal view returns(bool) {
        address contractCreator = IGenericContract(contractAddress).creator();
        address senderGroupAddress = userManager.getGroupFromStore(senderAddress);

        return (
            contractCreator == senderGroupAddress ||
            contractCreator == senderAddress || 
            uint8(userManager.getContractBERelation(contractAddress, senderAddress)) > 1 ||
            uint8(userManager.getContractBERelation(contractAddress, senderGroupAddress)) > 1
        );
    }

    function checkCreateInFactory(
        address creatorAddress,
        ContractType targetType
    ) public view returns(bool, string memory){
        if(uint8(userManager.getUserType(creatorAddress)) <= 2){
            return(false, "creatorAddress UserType do not have permission");
        }
        if(targetType != ContractType.POINT){
            return(false, "ContractType not support");
        }
        if(userManager.getCreationAddressList(creatorAddress, targetType).length >= adminControler.getCreationLimit(targetType)){
            return(false, "Reached creation limit");
        }
        if(_isInsufficientCredit(creatorAddress, "createInFactory")){
            return(false, "creatorAddress insufficient credit");
        }
        return (true, "");
    }

    // creation
    function createInFactory(
        address creatorAddress,  
        ContractType targetType, 
        string calldata name, 
        string calldata symbol, 
        uint8 decimals
    ) external onlyRouterAdmin returns(uint256){
        (bool result, string memory errorMessage) = checkCreateInFactory(creatorAddress, targetType);
        require(result, errorMessage);

        address newCreationAddress = pointFactory.createPoint(creatorAddress, targetType, name, symbol, decimals);
        userManager.addToCreationList(newCreationAddress);
        emit ContractCreated(targetType, newCreationAddress, creatorAddress);
        return _payFee(creatorAddress, "createInFactory");
    }


    function checkDistribution(
        address contractAddress, 
        address senderAddress, 
        uint256 amount
    ) public view returns(bool, string memory) {
        if(!_isOriginalContract(contractAddress)){
            return(false, "contractAddress is not carina original contract");
        } else {
            if(
                IGenericContract(contractAddress).thisContractType() != ContractType.POINT &&
                IGenericContract(contractAddress).thisContractType() != ContractType.CREDITPOINT
            ){
                return(false, "ContractType not support");
            }
            if(!_isContractPermittedSender(contractAddress, senderAddress)){
                return(false, "senderAddress has no permission");
            }
            if(amount > pointFactory.getDistributeLimit(contractAddress)){
                return(false, "amount over the distribution limit");
            }
            if(_isInsufficientCredit(_getFeePayer(contractAddress, senderAddress), "distribution")){
                return(false, "Fee payerAddress insufficient credit");
            }
        }
        return (true, "");
    }

    // distribute
    function distribution(
        address contractAddress, 
        address senderAddress, 
        address userAddress, 
        uint256 amount
    ) external onlyRouterAdmin returns(uint256){
        (bool result, string memory errorMessage) = checkDistribution(contractAddress, senderAddress, amount);
        require(result, errorMessage);

        pointFactory.distributePoint(contractAddress, senderAddress, userAddress, amount);
        return _payFee(_getFeePayer(contractAddress, senderAddress), "distribution");
    }

    function checkDeduction(
        address contractAddress, 
        address senderAddress,
        address userAddress,
        uint256 amount
    ) public view returns(bool, string memory) {
        if(!_isOriginalContract(contractAddress)){
            return(false, "contractAddress is not carina original contract");
        } else {
            if(IGenericContract(contractAddress).thisContractType() != ContractType.POINT){
                return(false, "ContractType not support");
            }
            if(!_isContractPermittedSender(contractAddress, senderAddress)){
                return(false, "senderAddress has no permission");
            }
            if(amount > IGenericContract(contractAddress).balanceOf(userAddress)){
                return(false, "Insufficient balance");
            }
            if(_isInsufficientCredit(_getFeePayer(contractAddress, senderAddress), "deduction")){
                return(false, "Fee payerAddress insufficient credit");
            }
        }
        return (true, "");
    }

    // sender take creation from user
    function deduction(
        address contractAddress, 
        address senderAddress, 
        address userAddress, 
        uint256 amount
    ) external onlyRouterAdmin returns(uint256){
        (bool result, string memory errorMessage) = checkDeduction(contractAddress, senderAddress, userAddress, amount);
        require(result, errorMessage);
        
        pointFactory.deductPoint(contractAddress, senderAddress, userAddress, amount);
        return _payFee(_getFeePayer(contractAddress, senderAddress), "deduction");
    }

    function checkContractTransfer(
        address contractAddress, 
        address fromAddress, 
        address toAddress, 
        uint256 amount
    ) public view returns(bool, string memory) {
        if(!_isOriginalContract(contractAddress)){
            return(false, "contractAddress is not carina original contract");
        } else {
            if(
                IGenericContract(contractAddress).thisContractType() != ContractType.POINT &&
                IGenericContract(contractAddress).thisContractType() != ContractType.CREDITPOINT
            ){
                return(false, "ContractType not support");
            }
            if(uint8(userManager.getUserType(fromAddress)) <= 1){
                return(false, "fromAddress is not registered");
            }
            if(amount > IGenericContract(contractAddress).balanceOf(fromAddress)){
                return(false, "fromAddress Insufficient balance");
            }
            if(uint8(userManager.getUserType(toAddress)) <= 1){
                return(false, "toAddress is not registered");
            }
            if(_isInsufficientCredit(fromAddress, "contractTransfer")){
                return(false, "fromAddress insufficient credit");
            }
        }
        return (true, "");
    }

    // creation transfer, from address pay fee
    function contractTransfer(
        address contractAddress, 
        address fromAddress, 
        address toAddress, 
        uint256 amount
    ) external onlyRouterAdmin returns(uint256){
        (bool result, string memory errorMessage) = checkContractTransfer(contractAddress, fromAddress, toAddress, amount);
        require(result, errorMessage);

        pointFactory.transferPoint(contractAddress, fromAddress, toAddress, amount);
        return _payFee(fromAddress, "contractTransfer");
    }

    function checkChangeContractDistributeLimit(
        address contractAddress, 
        address senderAddress, 
        uint256 newValue
    ) public view returns(bool, string memory) {
        if(!_isOriginalContract(contractAddress)){
            return(false, "contractAddress is not carina original contract");
        } else {
            if(senderAddress != IGenericContract(contractAddress).creator()){
                return(false, "senderAddress is not contract creator");
            }
            if(newValue == pointFactory.getDistributeLimit(contractAddress)){
                return(false, "newValue is same as now");
            }
            if(_isInsufficientCredit(senderAddress, "changeContractDistributeLimit")){
                return(false, "senderAddress insufficient credit");
            }
        }
        return (true, "");
    }

    // change contract distribute limit
    function changeContractDistributeLimit(
        address contractAddress, 
        address senderAddress, 
        uint256 newValue
    ) external onlyRouterAdmin returns(uint256){
        (bool result, string memory errorMessage) = checkChangeContractDistributeLimit(contractAddress, senderAddress, newValue);
        require(result, errorMessage);

        pointFactory.changePointDistributeLimit(contractAddress, newValue);
        return _payFee(senderAddress, "changeContractDistributeLimit");
    }

    function checkChangeContractCreator(
        address contractAddress,
        address senderAddress,
        address newCreator
    ) public view returns(bool, string memory) {
        ContractType contractType = IGenericContract(contractAddress).thisContractType();

        if(!_isOriginalContract(contractAddress)){
            return(false, "contractAddress is not carina original contract");
        } else {
            if(contractType != ContractType.POINT){
                return(false, "ContractType not support");
            }
            if(senderAddress != IGenericContract(contractAddress).creator()){
                return(false, "senderAddress is not contract creator");
            }
            if(uint8(userManager.getUserType(newCreator)) <= 2){
                return(false, "newCreator UserType do not have permission");
            }
            if(userManager.getCreationAddressList(newCreator, contractType).length >= adminControler.getCreationLimit(contractType)){
                return(false, "newCreator Reached creation limit");
            }
            if(_isInsufficientCredit(senderAddress, "changeContractCreator")){
                return(false, "senderAddress insufficient credit");
            }
        }
        return (true, "");
    }

    // change creation creator， not over the creation limit
    function changeContractCreator(
        address contractAddress,
        address senderAddress,
        address newCreator
    ) external onlyRouterAdmin returns(uint256){
        (bool result, string memory errorMessage) = checkChangeContractCreator(contractAddress, senderAddress, newCreator);
        require(result, errorMessage);

        userManager.removeFromCreationList(contractAddress);
        pointFactory.changePointCreator(senderAddress, contractAddress, newCreator);
        userManager.addToCreationList(contractAddress);
        return _payFee(senderAddress, "changeContractCreator");
    }

    function checkChangeContractPausedStatus(
        address contractAddress, 
        address senderAddress, 
        bool newValue
    ) public view returns(bool, string memory) {
        if(!_isOriginalContract(contractAddress)){
            return(false, "contractAddress is not carina original contract");
        } else {
            if(IGenericContract(contractAddress).thisContractType() != ContractType.POINT){
                return(false, "ContractType not support");
            }
            if(senderAddress != IGenericContract(contractAddress).creator()){
                return(false, "senderAddress is not contract creator");
            }
            if(newValue == IGenericContract(contractAddress).paused()){
                return(false, "newValue is same as now");
            }
            if(_isInsufficientCredit(senderAddress, "changeContractPausedStatus")){
                return(false, "senderAddress insufficient credit");
            }
        }
        return (true, "");
    }

    // change contract Paused status
    function changeContractPausedStatus(
        address contractAddress, 
        address senderAddress, 
        bool newValue
    ) external onlyRouterAdmin returns(uint256){
        (bool result, string memory errorMessage) = checkChangeContractPausedStatus(contractAddress, senderAddress, newValue);
        require(result, errorMessage);

        pointFactory.setPointPauseStatus(contractAddress, senderAddress, newValue);
        return _payFee(senderAddress, "changeContractPausedStatus");
    }

    function checkManageUserRegistration(
        address userAddress,
        UserType userType
    ) public view returns(bool, string memory) {
        return userManager.checkManageUserType(userAddress, userType);
    }

    function manageUserRegistration(
        address userAddress,
        UserType userType
    ) external onlyRouterAdmin {
        userManager.manageUserType(userAddress, userType);
    }

    function checkManageGroupStore(
        address groupAddress, 
        address storeAddress, 
        RelationType relationType
    ) public view returns(bool, string memory) {
        return userManager.checkManageGroupStore(groupAddress, storeAddress, relationType);
    }

    function manageGroupStore(
        address groupAddress, 
        address storeAddress,
        RelationType relationType
    ) external onlyRouterAdmin returns(uint256){
        userManager.manageGroupStore(groupAddress, storeAddress, relationType);
        return _payFee(groupAddress, "manageGroupStore");
    }

    function checkManageContractBE(
        address senderAddress,
        address contractAddress,
        address businessEntityAddress,
        RelationType targetType
    ) public view returns(bool, string memory)  {
        return userManager.checkManageContractBE(senderAddress, contractAddress, businessEntityAddress, targetType);
    }

    function manageContractBE(
        address senderAddress,
        address contractAddress,
        address businessEntityAddress,
        RelationType targetType
    ) external onlyRouterAdmin returns(uint256){        
        userManager.manageContractBE(senderAddress, contractAddress, businessEntityAddress, targetType);
        return _payFee(senderAddress, "manageContractBE");
    }

}