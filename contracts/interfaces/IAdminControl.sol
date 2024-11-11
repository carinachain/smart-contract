// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../utils/CRNEnums.sol";

interface IAdminControl {
    event AdminAddressAdded(
        ContractType indexed creationType,
        address indexed addAdminAddress
    );
    event AdminAddressRemoved(
        ContractType indexed creationType,
        address indexed removeAdminAddress
    );
    event ContractAddressSet(
        ContractType indexed contractType,
        address indexed previousContractAddress,
        address indexed newContractAddress
    );
    event CreationLimitSet(
        ContractType indexed contractType,
        uint256 previousValue,
        uint256 newValue
    );
    event FunctionExpenseSet(
        address indexed contractAddress,
        string functionName,
        uint256 previousValue,
        uint256 newValue
    );
    event CreationTransferSwitchChanged(
        address indexed contractAddress,
        bool switchOnStatus
    );
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    function COPYRIGHT() external view returns (string memory);
    function DEV() external view returns (string memory);
    function CONTRACT() external view returns (string memory);
    function thisContractType() external view returns (ContractType);
    function owner() external view returns (address);

    function renounceOwnership() external;
    function transferOwnership(address newOwner) external;

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
    function contractTransferSwithOnList(
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
}
