// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ShareEnums.sol";

interface IUserManager {
    event UserSet(address indexed userAddress, UserType indexed userType);
    event GroupStoreRelationChanged(
        address indexed groupAddress, 
        address indexed storeAddress, 
        RelationType previousType, 
        RelationType indexed newType
    );
    event ContractBusinessEntityChanged(
        address indexed contractAddress, 
        address indexed beAddress, 
        RelationType previousType, 
        RelationType indexed newType
    );

    function getUserType(address userAddress) external view returns (UserType);

    function checkManageUserType(
        address userAddress, 
        UserType userType
    ) external view returns (bool, string memory);

    function manageUserType(
        address userAddress, 
        UserType userType
    ) external;

    function getCreationAddressList(
        address creatorAddress, 
        ContractType targetType
    ) external view returns (address[] memory);

    function addToCreationList(address addCreationAddress) external;

    function removeFromCreationList(address removeCreationAddress) external;

    function getStoreGroupRelation(
        address storeAddress, 
        address groupAddress
    ) external view returns (RelationType);

    function getGroupStoresList(
        address groupAddress
    ) external view returns (address[] memory, address[] memory);

    function getGroupFromStore(address storeAddress) external view returns (address);

    function checkManageGroupStore(
        address groupAddress, 
        address storeAddress, 
        RelationType relationType
    ) external view returns (bool, string memory);

    function manageGroupStore(
        address groupAddress, 
        address storeAddress, 
        RelationType relationType
    ) external;

    function getContractBERelation(
        address contractAddress, 
        address businessEntityAddress
    ) external view returns (RelationType);

    function getContractBEList(
        address contractAddress, 
        UserType userTypeValue
    ) external view returns (address[] memory, address[] memory);

    function checkManageContractBE(
        address senderAddress, 
        address contractAddress, 
        address businessEntityAddress, 
        RelationType targetType
    ) external view returns (bool, string memory);

    function manageContractBE(
        address senderAddress, 
        address contractAddress, 
        address businessEntityAddress, 
        RelationType targetType
    ) external;

    function getAllOperatableContractAddress(
        address targetAddress, 
        ContractType targetType
    ) external view returns (
        address[] memory, 
        address[] memory, 
        address[] memory, 
        address[] memory, 
        address[] memory, 
        address[] memory
    );
}