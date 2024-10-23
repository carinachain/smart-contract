// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ShareEnums.sol";

interface IRouter {
    event ContractCreated(
        ContractType indexed contractType, 
        address indexed newCreationAddress, 
        address indexed creatorAddress
    );

    function getFeePayer(
        address contractAddress, 
        address senderAddress
    ) external view returns (address);

    function checkCreateInFactory(
        address creatorAddress,
        ContractType targetType
    ) external view returns (bool, string memory);

    function createInFactory(
        address creatorAddress,  
        ContractType targetType, 
        string calldata name, 
        string calldata symbol, 
        uint8 decimals
    ) external returns (uint256);

    function checkDistribution(
        address contractAddress, 
        address senderAddress, 
        uint256 amount
    ) external view returns (bool, string memory);

    function distribution(
        address contractAddress, 
        address senderAddress, 
        address userAddress, 
        uint256 amount
    ) external returns (uint256);

    function checkDeduction(
        address contractAddress, 
        address senderAddress,
        address userAddress,
        uint256 amount
    ) external view returns (bool, string memory);

    function deduction(
        address contractAddress, 
        address senderAddress, 
        address userAddress, 
        uint256 amount
    ) external returns (uint256);

    function checkContractTransfer(
        address contractAddress, 
        address fromAddress, 
        address toAddress, 
        uint256 amount
    ) external view returns (bool, string memory);

    function contractTransfer(
        address contractAddress, 
        address fromAddress, 
        address toAddress, 
        uint256 amount
    ) external returns (uint256);

    function checkChangeContractDistributeLimit(
        address contractAddress, 
        address senderAddress, 
        uint256 newValue
    ) external view returns (bool, string memory);

    function changeContractDistributeLimit(
        address contractAddress, 
        address senderAddress, 
        uint256 newValue
    ) external returns (uint256);

    function checkChangeContractCreator(
        address contractAddress,
        address senderAddress,
        address newCreator
    ) external view returns (bool, string memory);

    function changeContractCreator(
        address contractAddress,
        address senderAddress,
        address newCreator
    ) external returns (uint256);

    function checkChangeContractPausedStatus(
        address contractAddress, 
        address senderAddress, 
        bool newValue
    ) external view returns (bool, string memory);

    function changeContractPausedStatus(
        address contractAddress, 
        address senderAddress, 
        bool newValue
    ) external returns (uint256);

    function checkManageUserRegistration(
        address userAddress,
        UserType userType
    ) external view returns (bool, string memory);

    function manageUserRegistration(
        address userAddress,
        UserType userType
    ) external;

    function checkManageGroupStore(
        address groupAddress, 
        address storeAddress, 
        RelationType relationType
    ) external view returns (bool, string memory);

    function manageGroupStore(
        address groupAddress, 
        address storeAddress,
        RelationType relationType
    ) external returns (uint256);

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
    ) external returns (uint256);
}