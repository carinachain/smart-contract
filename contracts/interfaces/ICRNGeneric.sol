// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../utils/CRNEnums.sol";

interface ICRNGeneric {
    // Generic Function
    function thisContractType() external view returns (ContractType);
    function adminControl() external view returns (address);
    function owner() external view returns (address);
    function currentEpoch() external view returns (uint256);
    function updateAdminControl() external;
    function updateAdmin() external;

    // AdminControl
    function adminStatus(
        ContractType contractType,
        address admin
    ) external view returns (bool);
    function currentAdminEpoch(
        ContractType contractType
    ) external view returns (uint256);
    function contractAddressBook(
        ContractType contractType
    ) external view returns (address);
    function creationTypeLimit(
        ContractType contractType
    ) external view returns (uint256);
    function functionExpenseList(
        bytes32 functionKey
    ) external view returns (uint256);
    function isContractTransferSwithOn(
        address contractAddress
    ) external view returns (bool);
    function addAdmin(
        address addAdminAddress,
        ContractType contractType
    ) external;
    function removeAdmin(
        address removeAdminAddress,
        ContractType contractType
    ) external;
    function getAdminList(
        ContractType contractType
    ) external view returns (address[] memory);
    function setContractAddress(address contractAddress) external;
    function setCreationLimit(
        ContractType targetType,
        uint256 newCreationLimitValue
    ) external;
    function getFunctionExpense(
        address contractAddress,
        string calldata functionName
    ) external view returns (uint256);
    function setFunctionExpense(
        address contractAddress,
        string calldata functionName,
        uint256 newExpenseValue
    ) external;
    function isInsufficientCredit(
        address payerAddress,
        address contractAddress,
        string memory functionName
    ) external view returns (bool, uint256);
    function payExpense(
        address payerAddress,
        address contractAddress,
        string memory functionName
    ) external returns (bool, uint256);
    function changeCreationTransferSwitch(
        address contractAddress,
        bool newSwitchOnStatus
    ) external;
    function getCreatorCreationAddressList(
        address creatorAddress,
        ContractType targetType
    ) external view returns (address[] memory);
    function getCreationAddressList(
        ContractType targetType
    ) external view returns (address[] memory);
    function whenCreationCreated(
        address creatorAddress,
        ContractType contractType,
        address creationAddress
    ) external;
    function whenCreatorChanged(
        address creationAddress,
        ContractType contractType,
        address previousCreator,
        address newCreator
    ) external;
    function isOverCreationTypeLimit(
        address creatorAddress,
        ContractType contractType
    ) external view returns (bool);

    // CRNFactory
    function getSenderCreatedPointList(
        address targetAddress
    ) external view returns (address[] memory);

    // Pointfactory
    function createPoint(
        address creatorAddress,
        string calldata name,
        string calldata symbol,
        uint8 decimals
    ) external returns (address);

    // MembershipFactory
    function createMembership(
        address creatorAddress
    ) external returns (address);

    // UserManager
    function userTypeInfo(address user) external view returns (UserType);
    function storeGroupRelationInfo(
        address store,
        address group
    ) external view returns (RelationType);
    function storeToGroup(address store) external view returns (address);
    function contractBusinessEntityRelationInfo(
        address contractAddress,
        address entity
    ) external view returns (RelationType);
    function checkManageUserType(
        address userAddress,
        UserType userType
    ) external view returns (bool, string memory);
    function manageUserType(
        address userAddress,
        UserType userType
    ) external returns (bool);
    function getGroupStoresList(
        address groupAddress
    ) external view returns (address[] memory, address[] memory);
    function checkManageGroupStore(
        address groupAddress,
        address storeAddress,
        RelationType relationType
    ) external view returns (bool, string memory);
    function manageGroupStore(
        address groupAddress,
        address storeAddress,
        RelationType relationType
    ) external returns (bool);
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
    ) external returns (bool);
    function getAllOperatableContractAddress(
        address targetAddress,
        ContractType targetType
    )
        external
        view
        returns (
            address[] memory,
            address[] memory,
            address[] memory,
            address[] memory,
            address[] memory,
            address[] memory
        );
    function getPayerAddress(
        address contractAddress,
        address senderAddress
    ) external view returns (address);
    function checkSenderPermission(
        address contractAddress,
        address senderAddress
    ) external view returns (bool);

    // Creation contract
    function creator() external view returns (address);
    function changeCreator(
        address senderAddress,
        address newCreator
    ) external returns (bool);

    // Point
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function paused() external view returns (bool);
    function distributeLimit() external view returns (uint256);
    function transferSwitch() external view returns (bool);
    function getAddressBalanceTimeStamp(
        address targetAddress
    ) external view returns (uint256, uint256);
    function distribute(
        address userAddress,
        uint256 amount
    ) external returns (bool);
    function deduct(
        address userAddress,
        uint256 amount
    ) external returns (bool);
    function pTransfer(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
    function changePauseStatus(
        address senderAddress,
        bool newValue
    ) external returns (bool);
    function setDistributeLimit(
        address senderAddress,
        uint256 newValue
    ) external returns (bool);
    function updateTransferSwitch() external;

    // Membership
    function levelName(uint256 level) external view returns (string memory);
    function hasMembership(address member) external view returns (bool);
    function defineLevelBatch(
        address senderAddress,
        uint256[] memory levelNumberArray,
        string[] memory levelNameList
    ) external returns (bool);
    function defineLevel(
        address senderAddress,
        uint256 levelNumber,
        string memory targetlevelName
    ) external returns (bool);
    function issueMembership(
        address senderAddress,
        address memberAddress,
        uint256 level
    ) external returns (bool);
    function revokeMembership(
        address senderAddress,
        address memberAddress
    ) external returns (bool);
    function getMemberList(
        uint256 level
    ) external view returns (address[] memory);
    function getMemberInfo(
        address memberAddress
    ) external view returns (bool, uint256);
    function changeMemberLevel(
        address senderAddress,
        address memberAddress,
        uint256 level
    ) external returns (bool);
}
