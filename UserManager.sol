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

    mapping(address => UserType) private userTypeInfo;

    mapping(address => mapping(ContractType => address[])) private creationList;

    struct AddressList {
        address[] FeeFree;
        address[] FeeSelfPay;
    }

    mapping(address => AddressList) private merchentStoresList;

    mapping(address => mapping(address => RelationType)) private storeMerchantRelationInfo;

    mapping(address => address) private storeToMerchant;

    mapping(address => address[]) private clerksList;

    // 7/13 change to store
    mapping(address => address) private clerkToStore;

    // 7/13 change to BusinessEntity
    mapping(address => AddressList) private contractBusinessEntityList;

    // 7/13 change to BusinessEntity
    mapping(address => mapping(address => RelationType)) private contractBusinessEntityRelationInfo;

    // 7/13 chenge to operatable
    mapping(address => AddressList) private operatableContractsList;


    event UserSet(address indexed userAddress, UserType indexed userType);
    event MerchantStoreRelationChanged(address indexed userAddress, address indexed targetAddress, RelationType indexed newRelationType, RelationType previousRelationType);
    event ContractBusinessEntityChanged(address indexed contractAddress, address indexed operatorAddress, RelationType indexed newType, RelationType previousType);
    event ClerksListChanged(address indexed storeAddress, address indexed clerkAddress, bool indexed isAdd);

    modifier onlyUserAdmin() {
        require(adminControler.checkAdmin(msg.sender, thisContractType), "Need admin");
        _;
    }


    modifier onlyOriginalContract(address targetAddress) {
        bool result;
        try IGenericContract(targetAddress).thisContractType() returns (ContractType) {
            result = true;
        } catch {
            result = false;
        }
        require(result, "Not original contract");
        _;
    }
    
    constructor (address adminControlerAddress) {
        adminControler = AdminControler(adminControlerAddress);

        userTypeInfo[AdminControler(adminControlerAddress).owner()] = UserType.ADMINISTRATOR;

        address CCRAddress = adminControler.getContractAddress(ContractType.CREDITPOINT);
        creationList[IGenericContract(CCRAddress).creator()][ContractType.CREDITPOINT].push(CCRAddress);
        userTypeInfo[IGenericContract(CCRAddress).creator()] = UserType.SERVICEPROVIDER;

        address pCRNAddress = adminControler.getContractAddress(ContractType.POINTCRN);
        creationList[IGenericContract(pCRNAddress).creator()][ContractType.POINTCRN].push(pCRNAddress);
        userTypeInfo[IGenericContract(pCRNAddress).creator()] = UserType.SERVICEPROVIDER;
    }


    function getUserType(
        address userAddress
    ) external view returns (UserType) {
        return userTypeInfo[userAddress];
    }

    // add/remove
    function manageUser(
        address userAddress, 
        UserType userType
    ) external onlyUserAdmin {
        require(userAddress != address(0), "Invalid address");
        if(userTypeInfo[userAddress] == UserType.DELETED){
            revert("User was deleted");
        } else if(userTypeInfo[userAddress] == UserType.UNREGISTERED) {
            require(uint8(userType) > 1, "Invalid type");
        } else if(userType != UserType.DELETED){
            revert("Can only set once");
        } 

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

    // check if address is already in list
    function _isInList(
        address[] memory list, 
        address targetAddress
    ) internal pure returns (bool) {
        for (uint256 i = 0; i < list.length; i++) {
            if (list[i] == targetAddress) {
                return true;
            }
        }
        return false;
    }

    // add user's creation address to user's list
    function addToCreationList(
        address addCreationAddress
    ) external onlyUserAdmin onlyOriginalContract(addCreationAddress) {
        address creatorAddress = IGenericContract(addCreationAddress).creator();
        ContractType contractType = IGenericContract(addCreationAddress).thisContractType();
        address[] memory addressList = creationList[creatorAddress][contractType];
        require(!_isInList(addressList, addCreationAddress), "Already added");
        creationList[creatorAddress][contractType].push(addCreationAddress);
    }

    // remove creation address from user's list
    function removeFromCreationList(
        address removeCreationAddress
    ) external onlyUserAdmin onlyOriginalContract(removeCreationAddress) {
        address creatorAddress = IGenericContract(removeCreationAddress).creator();
        ContractType contractType = IGenericContract(removeCreationAddress).thisContractType();
        address[] storage addresses = creationList[creatorAddress][contractType];
        require(_isInList(addresses, removeCreationAddress), "Not in the list");
        for (uint256 i = 0; i < addresses.length; i++) {
            if (addresses[i] == removeCreationAddress) {
                addresses[i] = addresses[addresses.length - 1];
                addresses.pop();
                break;
            }
        }
    }

    function getStoreMerchantRelation(
        address storeAddress,
        address merchantAddress
    ) external view returns(RelationType) {
        return storeMerchantRelationInfo[storeAddress][merchantAddress];
    }

    function getMerchantStoresList(
        address merchantAddress,
        RelationType relationType
    ) external view returns(address[] memory) {
        if(relationType == RelationType.FEEFREE) {
            return merchentStoresList[merchantAddress].FeeFree;
        } else if(relationType == RelationType.FEESELFPAY) {
            return merchentStoresList[merchantAddress].FeeSelfPay;
        } else {
            revert("Invalid type");
        }
    }

    function getMerchantFromStore(address storeAddress) external view returns (address) {
        return storeToMerchant[storeAddress];
    }

    function _addToMerchantStoresList(
        address merchantAddress, 
        address storeAddress, 
        RelationType relationType
    ) internal {
        if(relationType == RelationType.FEEFREE) {
            merchentStoresList[merchantAddress].FeeFree.push(storeAddress);
        } else if(relationType == RelationType.FEESELFPAY) {
            merchentStoresList[merchantAddress].FeeSelfPay.push(storeAddress);
        } else {
            revert("Invalid type");
        }
    } 

    function _removeFromMerchantStoresList(
        address merchantAddress, 
        address storeAddress
    ) internal {
        address[] storage addresses;
        if(storeMerchantRelationInfo[storeAddress][merchantAddress] == RelationType.FEEFREE) {
            addresses = merchentStoresList[merchantAddress].FeeFree;
        } else if(storeMerchantRelationInfo[storeAddress][merchantAddress] == RelationType.FEESELFPAY) {
            addresses = merchentStoresList[merchantAddress].FeeSelfPay;
        } else {
            revert("Not in the list");
        }
        
        for (uint256 i = 0; i < addresses.length; i++) {
            if (addresses[i] == storeAddress) {
                addresses[i] = addresses[addresses.length - 1];
                addresses.pop();
                break;
            }
        }
    }

    // set relation between Merchant and Store,  FEEFREE or FEESELFPAY
    function manageMerchantStoreRelation(
        address merchantAddress, 
        address storeAddress,
        RelationType relationType
    ) external onlyUserAdmin {
        require(userTypeInfo[merchantAddress] == UserType.MERCHANT, "MerchantAddress is not merchant");
        require(userTypeInfo[storeAddress] == UserType.STORE, "StoreAddress is not Store");
        require(relationType != RelationType.UNDEFINED, "Invalid type");

        RelationType previousRelationType = storeMerchantRelationInfo[storeAddress][merchantAddress];
        require(previousRelationType != relationType, "Already set");
        require(uint8(previousRelationType) > 1 || uint8(relationType) > 1, "Invalid type");

        address previousMerchantAddress = storeToMerchant[storeAddress];
        require(previousMerchantAddress == merchantAddress || previousMerchantAddress == address(0), "Store set by other merchant");

        if(uint8(previousRelationType) > 1) {
            _removeFromMerchantStoresList(merchantAddress, storeAddress);
        }

        if(relationType == RelationType.CLEARED){
            storeToMerchant[storeAddress] = address(0);
        } else {
            storeToMerchant[storeAddress] = merchantAddress;
            _addToMerchantStoresList(merchantAddress, storeAddress, relationType);
        }
        
        storeMerchantRelationInfo[storeAddress][merchantAddress] = relationType;

        emit MerchantStoreRelationChanged(merchantAddress, storeAddress, relationType, previousRelationType);

    }

    function getStoreFromClerk(address clerkAddress) external view returns(address){
        return clerkToStore[clerkAddress];
    }

    function getClerksList(address storeAddress) external view returns(address[] memory){
        return clerksList[storeAddress];
    }

    // clerks only can add to store's list
    function addClerk(
        address storeAddress,
        address clerkAddress
    ) external onlyUserAdmin {
        require(userTypeInfo[storeAddress] == UserType.STORE, "StoreAddress is not Store");
        require(userTypeInfo[clerkAddress] == UserType.CLERK, "ClerkAddress is not Clerk");
        require(clerkToStore[clerkAddress] != storeAddress, "Already added");
        require(clerkToStore[clerkAddress] == address(0), "Clerk's store already set");
        clerkToStore[clerkAddress] = storeAddress;
        clerksList[storeAddress].push(clerkAddress);

        emit ClerksListChanged(storeAddress, clerkAddress, true);
    }

    function removeClerk(
        address storeAddress,
        address removeClerkAddress
    ) external onlyUserAdmin {
        require(clerkToStore[removeClerkAddress] == storeAddress, "Not store's clerk");
        
        for (uint256 i = 0; i < clerksList[storeAddress].length; i++) {
            if (clerksList[storeAddress][i] == removeClerkAddress) {
                clerksList[storeAddress][i] = clerksList[storeAddress][clerksList[storeAddress].length - 1];
                clerksList[storeAddress].pop();
                break;
            }
        }
        clerkToStore[removeClerkAddress] = address(0);

        emit ClerksListChanged(storeAddress, removeClerkAddress, false);
    }

    // Contract businessEntity means Merchants/Stores who can use this contract in router
    function getContractBERelation(
        address contractAddress,
        address businessEntityAddress
    ) external view returns (RelationType) {
        return contractBusinessEntityRelationInfo[contractAddress][businessEntityAddress];
    }

    function getOperatableContractsList(
        address businessEntityAddress, 
        RelationType typeValue
    ) external view returns (address[] memory) {
        if(typeValue == RelationType.FEEFREE) {
            return operatableContractsList[businessEntityAddress].FeeFree;
        } else if(typeValue == RelationType.FEESELFPAY) {
            return operatableContractsList[businessEntityAddress].FeeSelfPay;
        } else {
            revert("Invalid type");
        }
    }

    function _removeFromOperatableContractsList(
        address businessEntityAddress,
        address removeContractAddress
    ) internal {
        RelationType typeValue = contractBusinessEntityRelationInfo[removeContractAddress][businessEntityAddress];
        address[] storage addresses;
        if(typeValue == RelationType.FEEFREE) {
            addresses = operatableContractsList[businessEntityAddress].FeeFree;
        } else if(typeValue == RelationType.FEESELFPAY) {
            addresses = operatableContractsList[businessEntityAddress].FeeSelfPay;
        } else {
            revert("Not in the list");
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
        RelationType typeValue
    ) external view returns(address[] memory){
        if(typeValue == RelationType.FEEFREE) {
            return contractBusinessEntityList[contractAddress].FeeFree;
        } else if(typeValue == RelationType.FEESELFPAY) {
            return contractBusinessEntityList[contractAddress].FeeSelfPay;
        } else {
            revert("Invalid type");
        }
    }

    function _removeFromContractBEList(
        address contractAddress,
        address removeAddress
    ) internal {
        address[] storage addresses;
        if(contractBusinessEntityRelationInfo[contractAddress][removeAddress] == RelationType.FEEFREE) {
            addresses = contractBusinessEntityList[contractAddress].FeeFree;
        } else if(contractBusinessEntityRelationInfo[contractAddress][removeAddress] == RelationType.FEESELFPAY) {
            addresses = contractBusinessEntityList[contractAddress].FeeSelfPay;
        } else {
            revert("Not in the list");
        }

        for (uint256 i = 0; i < addresses.length; i++) {
            if (addresses[i] == removeAddress) {
                addresses[i] = addresses[addresses.length - 1];
                addresses.pop();
                break;
            }
        }
    }

    // add/remove/change
    function manageContractBE(
        address senderAddress,
        address contractAddress,
        address businessEntityAddress,
        RelationType targetType
    ) external onlyUserAdmin onlyOriginalContract(contractAddress) {
        require(userTypeInfo[businessEntityAddress] == UserType.STORE || userTypeInfo[businessEntityAddress] == UserType.MERCHANT, "BE must be Merchant/Store");

        require(senderAddress == IGenericContract(contractAddress).creator(), "Only for contract creator");

        RelationType businessEntityCreatorRelation = storeMerchantRelationInfo[businessEntityAddress][IGenericContract(contractAddress).creator()];
        require(targetType != businessEntityCreatorRelation, "Already had authorization");

        require(targetType != RelationType.UNDEFINED, "Invalid type");
        RelationType previousRelationType = contractBusinessEntityRelationInfo[contractAddress][businessEntityAddress];
        require(previousRelationType != targetType, "Already set");
        require(uint8(previousRelationType) > 1 || uint8(targetType) > 1, "Invalid type");

        if(uint8(previousRelationType) > 1) {
            _removeFromOperatableContractsList(businessEntityAddress, contractAddress);
            _removeFromContractBEList(contractAddress, businessEntityAddress);
        } 

        if(targetType == RelationType.FEEFREE) {
            operatableContractsList[businessEntityAddress].FeeFree.push(contractAddress);
            contractBusinessEntityList[contractAddress].FeeFree.push(businessEntityAddress);
        } else if(targetType == RelationType.FEESELFPAY) {
            operatableContractsList[businessEntityAddress].FeeSelfPay.push(contractAddress);
            contractBusinessEntityList[contractAddress].FeeSelfPay.push(businessEntityAddress);
        }

        contractBusinessEntityRelationInfo[contractAddress][businessEntityAddress] = targetType;
        
        emit ContractBusinessEntityChanged(contractAddress, businessEntityAddress, targetType, previousRelationType);
    }
}