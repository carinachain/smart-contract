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

    mapping(address => AddressList) private tenantStoresList;

    mapping(address => mapping(address => RelationType)) private storeTenantRelationInfo;

    mapping(address => address) private storeToTenant;

    mapping(address => address[]) private clerksList;

    mapping(address => address) private clerkToMerchant;

    mapping(address => AddressList) private contractMerchantsList;

    mapping(address => mapping(address => RelationType)) private contractMerchantRelationInfo;

    mapping(address => AddressList) private merchantContractsList;


    event UserSet(address indexed userAddress, UserType indexed userType);
    event TenantStoreRelationChanged(address indexed userAddress, address indexed targetAddress, RelationType indexed newRelationType, RelationType previousRelationType);
    event ContractMerchantChanged(address indexed contractAddress, address indexed operatorAddress, RelationType indexed newType, RelationType previousType);
    event ClerksListChanged(address indexed merchantAddress, address indexed clerkAddress, bool indexed isAdd);

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

    function getStoreTenantRelation(
        address storeAddress,
        address tenantAddress
    ) external view returns(RelationType) {
        return storeTenantRelationInfo[storeAddress][tenantAddress];
    }

    function getTenantStoresList(
        address tenantAddress,
        RelationType relationType
    ) external view returns(address[] memory) {
        if(relationType == RelationType.FEEFREE) {
            return tenantStoresList[tenantAddress].FeeFree;
        } else if(relationType == RelationType.FEESELFPAY) {
            return tenantStoresList[tenantAddress].FeeSelfPay;
        } else {
            revert("Invalid type");
        }
    }

    function getTenantFromStore(address storeAddress) external view returns (address) {
        return storeToTenant[storeAddress];
    }

    function _addToTenantStoresList(
        address tenantAddress, 
        address storeAddress, 
        RelationType relationType
    ) internal {
        if(relationType == RelationType.FEEFREE) {
            tenantStoresList[tenantAddress].FeeFree.push(storeAddress);
        } else if(relationType == RelationType.FEESELFPAY) {
            tenantStoresList[tenantAddress].FeeSelfPay.push(storeAddress);
        } else {
            revert("Invalid type");
        }
    } 

    function _removeFromTenantStoresList(
        address tenantAddress, 
        address storeAddress
    ) internal {
        address[] storage addresses;
        if(storeTenantRelationInfo[storeAddress][tenantAddress] == RelationType.FEEFREE) {
            addresses = tenantStoresList[tenantAddress].FeeFree;
        } else if(storeTenantRelationInfo[storeAddress][tenantAddress] == RelationType.FEESELFPAY) {
            addresses = tenantStoresList[tenantAddress].FeeSelfPay;
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

    // set relation between Tenant and Store,  FEEFREE or FEESELFPAY
    function manageTenantStoreRelation(
        address tenantAddress, 
        address storeAddress,
        RelationType relationType
    ) external onlyUserAdmin {
        require(userTypeInfo[tenantAddress] == UserType.TENANT, "TenantAddress is not Tenant");
        require(userTypeInfo[storeAddress] == UserType.STORE, "StoreAddress is not Store");
        require(relationType != RelationType.UNDEFINED, "Invalid type");

        RelationType previousRelationType = storeTenantRelationInfo[storeAddress][tenantAddress];
        require(previousRelationType != relationType, "Already set");
        require(uint8(previousRelationType) > 1 || uint8(relationType) > 1, "Invalid type");

        address previousTenantAddress = storeToTenant[storeAddress];
        require(previousTenantAddress == tenantAddress || previousTenantAddress == address(0), "Store set by other tenant");

        if(uint8(previousRelationType) > 1) {
            _removeFromTenantStoresList(tenantAddress, storeAddress);
        }

        if(relationType == RelationType.CLEARED){
            storeToTenant[storeAddress] = address(0);
        } else {
            storeToTenant[storeAddress] = tenantAddress;
            _addToTenantStoresList(tenantAddress, storeAddress, relationType);
        }
        
        storeTenantRelationInfo[storeAddress][tenantAddress] = relationType;

        emit TenantStoreRelationChanged(tenantAddress, storeAddress, relationType, previousRelationType);

    }

    function getMerchantFromClerk(address clerkAddress) external view returns(address){
        return clerkToMerchant[clerkAddress];
    }

    function getClerksList(address storeAddress) external view returns(address[] memory){
        return clerksList[storeAddress];
    }

    // clerks only can add to store's list
    function addClerk(
        address merchantAddress,
        address clerkAddress
    ) external onlyUserAdmin {
        require(userTypeInfo[merchantAddress] == UserType.STORE || userTypeInfo[merchantAddress] == UserType.TENANT, "Merchant must be Tenant/Store");
        require(userTypeInfo[clerkAddress] == UserType.CLERK, "ClerkAddress is not Clerk");
        require(clerkToMerchant[clerkAddress] != merchantAddress, "Already added");
        require(clerkToMerchant[clerkAddress] == address(0), "Clerk's Merchant already set");
        clerkToMerchant[clerkAddress] = merchantAddress;
        clerksList[merchantAddress].push(clerkAddress);

        emit ClerksListChanged(merchantAddress, clerkAddress, true);
    }

    function removeClerk(
        address merchantAddress,
        address removeClerkAddress
    ) external onlyUserAdmin {
        require(clerkToMerchant[removeClerkAddress] == merchantAddress, "Not merchant's clerk");
        
        for (uint256 i = 0; i < clerksList[merchantAddress].length; i++) {
            if (clerksList[merchantAddress][i] == removeClerkAddress) {
                clerksList[merchantAddress][i] = clerksList[merchantAddress][clerksList[merchantAddress].length - 1];
                clerksList[merchantAddress].pop();
                break;
            }
        }
        clerkToMerchant[removeClerkAddress] = address(0);

        emit ClerksListChanged(merchantAddress, removeClerkAddress, false);
    }

    // ContractMerchant means Tenants/Stores who can use this contract in router
    function getContractMerchantRelation(
        address contractAddress,
        address merchantAddress
    ) external view returns (RelationType) {
        return contractMerchantRelationInfo[contractAddress][merchantAddress];
    }

    function getMerchantContractsList(
        address merchantAddress, 
        RelationType typeValue
    ) external view returns (address[] memory) {
        if(typeValue == RelationType.FEEFREE) {
            return merchantContractsList[merchantAddress].FeeFree;
        } else if(typeValue == RelationType.FEESELFPAY) {
            return merchantContractsList[merchantAddress].FeeSelfPay;
        } else {
            revert("Invalid type");
        }
    }

    function _removeFromMerchantContractsList(
        address merchantAddress,
        address removeContractAddress
    ) internal {
        RelationType typeValue = contractMerchantRelationInfo[removeContractAddress][merchantAddress];
        address[] storage addresses;
        if(typeValue == RelationType.FEEFREE) {
            addresses = merchantContractsList[merchantAddress].FeeFree;
        } else if(typeValue == RelationType.FEESELFPAY) {
            addresses = merchantContractsList[merchantAddress].FeeSelfPay;
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

    function getContractMerchantsList(
        address contractAddress,
        RelationType typeValue
    ) external view returns(address[] memory){
        if(typeValue == RelationType.FEEFREE) {
            return contractMerchantsList[contractAddress].FeeFree;
        } else if(typeValue == RelationType.FEESELFPAY) {
            return contractMerchantsList[contractAddress].FeeSelfPay;
        } else {
            revert("Invalid type");
        }
    }

    function _removeFromContractMerchantsList(
        address contractAddress,
        address removeMerchantAddress
    ) internal {
        address[] storage addresses;
        if(contractMerchantRelationInfo[contractAddress][removeMerchantAddress] == RelationType.FEEFREE) {
            addresses = contractMerchantsList[contractAddress].FeeFree;
        } else if(contractMerchantRelationInfo[contractAddress][removeMerchantAddress] == RelationType.FEESELFPAY) {
            addresses = contractMerchantsList[contractAddress].FeeSelfPay;
        } else {
            revert("Not in the list");
        }

        for (uint256 i = 0; i < addresses.length; i++) {
            if (addresses[i] == removeMerchantAddress) {
                addresses[i] = addresses[addresses.length - 1];
                addresses.pop();
                break;
            }
        }
    }

    // add/remove/change
    function manageContractMerchant(
        address senderAddress,
        address contractAddress,
        address merchantAddress,
        RelationType targetType
    ) external onlyUserAdmin onlyOriginalContract(contractAddress) {
        require(userTypeInfo[merchantAddress] == UserType.STORE || userTypeInfo[merchantAddress] == UserType.TENANT, "Merchant must be Tenant/Store");

        require(senderAddress == IGenericContract(contractAddress).creator(), "Only for contract creator");

        RelationType merchantCreatorRelation = storeTenantRelationInfo[merchantAddress][IGenericContract(contractAddress).creator()];
        require(targetType != merchantCreatorRelation, "Already had authorization");

        require(targetType != RelationType.UNDEFINED, "Invalid type");
        RelationType previousRelationType = contractMerchantRelationInfo[contractAddress][merchantAddress];
        require(previousRelationType != targetType, "Already set");
        require(uint8(previousRelationType) > 1 || uint8(targetType) > 1, "Invalid type");

        if(uint8(previousRelationType) > 1) {
            _removeFromMerchantContractsList(merchantAddress, contractAddress);
            _removeFromContractMerchantsList(contractAddress, merchantAddress);
        } 

        if(targetType == RelationType.FEEFREE) {
            merchantContractsList[merchantAddress].FeeFree.push(contractAddress);
            contractMerchantsList[contractAddress].FeeFree.push(merchantAddress);
        } else if(targetType == RelationType.FEESELFPAY) {
            merchantContractsList[merchantAddress].FeeSelfPay.push(contractAddress);
            contractMerchantsList[contractAddress].FeeSelfPay.push(merchantAddress);
        }

        contractMerchantRelationInfo[contractAddress][merchantAddress] = targetType;
        
        emit ContractMerchantChanged(contractAddress, merchantAddress, targetType, previousRelationType);
    }
}