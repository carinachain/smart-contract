// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ShareEnums.sol";
import "./AdminControler.sol";
import "./IGenericContract.sol";

contract UserManager {
    string public constant COPYRIGHT = "Copyright (c) 2024 CarinaChain.com All rights reserved.";
    string public constant DEV = "NebulaInfinity.com";
    ContractType public constant thisContractType = ContractType.USERMANAGER;

    AdminControler private adminControler;

    struct AddressList {
        address[] FeeFree;
        address[] FeeSelfPay;
    }

    mapping(address => UserType) private userTypeInfo;
    mapping(address => mapping(ContractType => address[])) private creationList;
    mapping(address => AddressList) private groupStoresList;
    mapping(address => mapping(address => RelationType)) private storeGroupRelationInfo;
    mapping(address => address) private storeToGroup;
    mapping(address => mapping(UserType => AddressList)) private contractBusinessEntityList;
    mapping(address => mapping(address => RelationType)) private contractBusinessEntityRelationInfo;
    mapping(address => mapping(ContractType => AddressList)) private beOperatableContractsList;

    event UserSet(address indexed userAddress, UserType indexed userType);
    event GroupStoreRelationChanged(address indexed groupAddress, address indexed storeAddress, RelationType previousType, RelationType indexed newType);
    event ContractBusinessEntityChanged(address indexed contractAddress, address indexed beAddress, RelationType previousType, RelationType indexed newType);

    modifier onlyUserManagerAdmin() {
        require(adminControler.checkAdmin(msg.sender, thisContractType), "Need UserManagerAdmin");
        _;
    }
    
    constructor (address adminControlerAddress) {
        adminControler = AdminControler(adminControlerAddress);

        userTypeInfo[AdminControler(adminControlerAddress).owner()] = UserType.ADMINISTRATOR;

        address CCRAddress = adminControler.getContractAddress(ContractType.CREDITPOINT);
        creationList[IGenericContract(CCRAddress).creator()][ContractType.CREDITPOINT].push(CCRAddress);

        address pCRNAddress = adminControler.getContractAddress(ContractType.POINTCRN);
        creationList[IGenericContract(pCRNAddress).creator()][ContractType.POINTCRN].push(pCRNAddress);
    }


    function getUserType(
        address userAddress
    ) external view returns (UserType) {
        return userTypeInfo[userAddress];
    }

    function checkManageUserType(
        address userAddress, 
        UserType userType
    ) public view returns (bool, string memory) {
        if(userAddress == address(0)){
            return (false, "userAddress cannot be zero");
        }
        if(userType == UserType.UNREGISTERED){
            return (false, "userType cannot be UNREGISTERED");
        }
        if(userTypeInfo[userAddress] == UserType.DELETED){
            return (false, "Deleted user cannot set");
        } else if(userTypeInfo[userAddress] == UserType.UNREGISTERED) {
            if(userType == UserType.DELETED) {
                return (false, "Can not set UNREGISTERED user to DELETED");
            }
        } else if(userType != UserType.DELETED){
            return (false, "UserType already set, cannot be modified");
        }
        return (true, "");
    }

    // add/remove
    function manageUserType(
        address userAddress, 
        UserType userType
    ) external onlyUserManagerAdmin {
        (bool checkResult, string memory errorMessage) = checkManageUserType(userAddress, userType);
        require(checkResult, errorMessage);

        userTypeInfo[userAddress] = userType;
        emit UserSet(userAddress, userType);
    }

    // get Creator's creation address list by creation type
    function getCreationAddressList(
        address creatorAddress, 
        ContractType targetType
    ) external view returns (address[] memory) {
        return creationList[creatorAddress][targetType];
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

    // add user's creation address to user's list
    function addToCreationList(
        address addCreationAddress
    ) external onlyUserManagerAdmin {
        require(_isOriginalContract(addCreationAddress), "addCreationAddress is not carina original contract");
        creationList[IGenericContract(addCreationAddress).creator()][IGenericContract(addCreationAddress).thisContractType()].push(addCreationAddress);
    }

    // remove creation address from user's list
    function removeFromCreationList(
        address removeCreationAddress
    ) external onlyUserManagerAdmin {
        require(_isOriginalContract(removeCreationAddress), "removeCreationAddress is not carina original contract");
        address[] storage addresses = creationList[IGenericContract(removeCreationAddress).creator()][IGenericContract(removeCreationAddress).thisContractType()];
        for (uint256 i = 0; i < addresses.length; i++) {
            if (addresses[i] == removeCreationAddress) {
                addresses[i] = addresses[addresses.length - 1];
                addresses.pop();
                break;
            }
        }
    }

    function getStoreGroupRelation(
        address storeAddress,
        address groupAddress
    ) external view returns(RelationType) {
        return storeGroupRelationInfo[storeAddress][groupAddress];
    }

    function getGroupStoresList(address groupAddress) external view returns(address[] memory, address[] memory) {
        return (
            groupStoresList[groupAddress].FeeFree,
            groupStoresList[groupAddress].FeeSelfPay
        );
    }

    function getGroupFromStore(address storeAddress) external view returns (address) {
        return storeToGroup[storeAddress];
    }

    function _addToGroupStoresList(
        address groupAddress, 
        address storeAddress, 
        RelationType relationType
    ) internal {
        if(relationType == RelationType.FEEFREE) {
            groupStoresList[groupAddress].FeeFree.push(storeAddress);
        } 
        if(relationType == RelationType.FEESELFPAY) {
            groupStoresList[groupAddress].FeeSelfPay.push(storeAddress);
        } 
    } 

    function _removeFromGroupStoresList(
        address groupAddress, 
        address storeAddress
    ) internal {
        address[] storage addresses;
        if(storeGroupRelationInfo[storeAddress][groupAddress] == RelationType.FEEFREE) {
            addresses = groupStoresList[groupAddress].FeeFree;
        } else if(storeGroupRelationInfo[storeAddress][groupAddress] == RelationType.FEESELFPAY) {
            addresses = groupStoresList[groupAddress].FeeSelfPay;
        } else {
            revert();
        }
        for (uint256 i = 0; i < addresses.length; i++) {
            if (addresses[i] == storeAddress) {
                addresses[i] = addresses[addresses.length - 1];
                addresses.pop();
                break;
            }
        }
    }

    function checkManageGroupStore(
        address groupAddress, 
        address storeAddress, 
        RelationType relationType
    ) public view returns(bool, string memory) {
        if(userTypeInfo[groupAddress] != UserType.GROUP){
            return(false, "groupAddress UserType must be GROUP");
        }
        if(userTypeInfo[storeAddress] != UserType.STORE){
            return(false, "storeAddress UserType must be STORE");
        }
        if(relationType == RelationType.UNDEFINED){
            return(false, "relationType cannot be UNDEFINED");
        }
        if((relationType == RelationType.CLEARED && uint8(storeGroupRelationInfo[storeAddress][groupAddress]) <= 1)){
            return(false, "Cannot change UNDEFINED/CLEARED to CLEARED");
        }
        if(relationType == storeGroupRelationInfo[storeAddress][groupAddress]){
            return(false, "relationType is same value as current");
        }
        if(storeToGroup[storeAddress] != groupAddress && storeToGroup[storeAddress] != address(0)){
            return(false, "Store already joined another group");
        }
        if(adminControler.isInsufficientCredit(groupAddress, msg.sender, "manageGroupStore")){
            return(false, "groupAddress insufficient credit");
        }
        return(true, "");
    }

    // set relation between Group and Store
    function manageGroupStore(
        address groupAddress, 
        address storeAddress,
        RelationType relationType
    ) external onlyUserManagerAdmin {
        (bool checkResult, string memory errorMessage) = checkManageGroupStore(groupAddress, storeAddress, relationType);
        require(checkResult, errorMessage);

        RelationType previousRelationType = storeGroupRelationInfo[storeAddress][groupAddress];
        if(uint8(previousRelationType) > 1) {
            _removeFromGroupStoresList(groupAddress, storeAddress);
        }
        if(relationType == RelationType.CLEARED){
            storeToGroup[storeAddress] = address(0);
        } else {
            storeToGroup[storeAddress] = groupAddress;
            _addToGroupStoresList(groupAddress, storeAddress, relationType);
        }
        storeGroupRelationInfo[storeAddress][groupAddress] = relationType;

        emit GroupStoreRelationChanged(groupAddress, storeAddress, previousRelationType, relationType);
    }

    // Contract businessEntity means Groups/Stores who can use this contract in router
    function getContractBERelation(
        address contractAddress,
        address businessEntityAddress
    ) external view returns (RelationType) {
        return contractBusinessEntityRelationInfo[contractAddress][businessEntityAddress];
    }

    function _removeFromBEOperatableContractsList(
        address businessEntityAddress,
        address removeContractAddress
    ) internal {
        RelationType typeValue = contractBusinessEntityRelationInfo[removeContractAddress][businessEntityAddress];
        ContractType contractType = IGenericContract(removeContractAddress).thisContractType();
        address[] storage addresses;
        if(typeValue == RelationType.FEEFREE) {
            addresses = beOperatableContractsList[businessEntityAddress][contractType].FeeFree;
        } else if(typeValue == RelationType.FEESELFPAY) {
            addresses = beOperatableContractsList[businessEntityAddress][contractType].FeeSelfPay;
        } else {
            revert();
        }

        for (uint256 i = 0; i < addresses.length; i++) {
            if (addresses[i] == removeContractAddress) {
                addresses[i] = addresses[addresses.length - 1];
                addresses.pop();
                break;
            }
        }
    }

    function getContractBEList(
        address contractAddress,
        UserType userTypeValue
    ) external view returns(address[] memory, address[] memory){
        return (
            contractBusinessEntityList[contractAddress][userTypeValue].FeeFree, 
            contractBusinessEntityList[contractAddress][userTypeValue].FeeSelfPay
        );
    }

    function _removeFromContractBEList(
        address contractAddress,
        address removeAddress
    ) internal {
        address[] storage addresses;
        if(contractBusinessEntityRelationInfo[contractAddress][removeAddress] == RelationType.FEEFREE) {
            addresses = contractBusinessEntityList[contractAddress][userTypeInfo[removeAddress]].FeeFree;
        } else if(contractBusinessEntityRelationInfo[contractAddress][removeAddress] == RelationType.FEESELFPAY) {
            addresses = contractBusinessEntityList[contractAddress][userTypeInfo[removeAddress]].FeeSelfPay;
        } else {
            revert();
        }

        for (uint256 i = 0; i < addresses.length; i++) {
            if (addresses[i] == removeAddress) {
                addresses[i] = addresses[addresses.length - 1];
                addresses.pop();
                break;
            }
        }
    }

    function checkManageContractBE(
        address senderAddress,
        address contractAddress,
        address businessEntityAddress,
        RelationType targetType
    ) public view returns(bool, string memory)  {        
        if(!_isOriginalContract(contractAddress)){
            return(false, "contractAddress is not carina original contract");
        } else {
            if(senderAddress != IGenericContract(contractAddress).creator()){
                return(false, "senderAddress is not contract creator");
            }
            if(uint8(userTypeInfo[businessEntityAddress]) <= 2){
                return(false, "businessEntityAddress UserType do not have permission");
            }
            if(targetType == RelationType.UNDEFINED){
                return(false, "targetType cannot be UNDEFINED");
            }
            if((targetType == RelationType.CLEARED && uint8(contractBusinessEntityRelationInfo[contractAddress][businessEntityAddress]) <= 1)){
                return(false, "Cannot change UNDEFINED/CLEARED to CLEARED");
            }
            if(targetType == contractBusinessEntityRelationInfo[contractAddress][businessEntityAddress]){
                return(false, "targetType is same value as current");
            }
            if(
                targetType == storeGroupRelationInfo[businessEntityAddress][IGenericContract(contractAddress).creator()] && 
                targetType != RelationType.CLEARED
            ){
                return(false, "businessEntityAddress already has same permission from parent group");
            }
            if(adminControler.isInsufficientCredit(senderAddress, msg.sender, "manageContractBE")){
                return(false, "senderAddress insufficient credit");
            }
        }
        return(true, "");
    }

    // add/remove/change
    function manageContractBE(
        address senderAddress,
        address contractAddress,
        address businessEntityAddress,
        RelationType targetType
    ) external onlyUserManagerAdmin {
        (bool result, string memory errorMessage) = checkManageContractBE(senderAddress, contractAddress, businessEntityAddress, targetType);
        require(result, errorMessage);

        RelationType previousRelationType = contractBusinessEntityRelationInfo[contractAddress][businessEntityAddress];
        ContractType contractType = IGenericContract(contractAddress).thisContractType();

        if(uint8(previousRelationType) > 1) {
            _removeFromBEOperatableContractsList(businessEntityAddress, contractAddress);
            _removeFromContractBEList(contractAddress, businessEntityAddress);
        } 
        if(targetType == RelationType.FEEFREE) {
            beOperatableContractsList[businessEntityAddress][contractType].FeeFree.push(contractAddress);
            contractBusinessEntityList[contractAddress][userTypeInfo[businessEntityAddress]].FeeFree.push(businessEntityAddress);
        } else if(targetType == RelationType.FEESELFPAY) {
            beOperatableContractsList[businessEntityAddress][contractType].FeeSelfPay.push(contractAddress);
            contractBusinessEntityList[contractAddress][userTypeInfo[businessEntityAddress]].FeeSelfPay.push(businessEntityAddress);
        }
        contractBusinessEntityRelationInfo[contractAddress][businessEntityAddress] = targetType;
        
        emit ContractBusinessEntityChanged(contractAddress, businessEntityAddress, previousRelationType, targetType);
    }

    function getAllOperatableContractAddress(
        address targetAddress, 
        ContractType targetType
    ) external view returns (address[] memory, address[] memory, address[] memory, address[] memory, address[] memory, address[] memory){
        address groupAddressFromStore = storeToGroup[targetAddress];
        return (
            creationList[targetAddress][targetType],
            creationList[groupAddressFromStore][targetType],
            beOperatableContractsList[targetAddress][targetType].FeeFree,
            beOperatableContractsList[targetAddress][targetType].FeeSelfPay,
            beOperatableContractsList[groupAddressFromStore][targetType].FeeFree,
            beOperatableContractsList[groupAddressFromStore][targetType].FeeSelfPay
        );
    }

}