// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./interfaces/ICRNGeneric.sol";

contract AdminControl is Initializable, OwnableUpgradeable {
    string public constant COPYRIGHT =
        "Copyright (c) 2024 CarinaChain.com All rights reserved.";
    string public constant DEV = "NebulaInfinity.com";

    ContractType public constant thisContractType = ContractType.ADMINCONTROL;
    string public CONTRACTVERSION;

    mapping(ContractType => mapping(address => bool)) public adminStatus;
    mapping(ContractType => address[]) private _creationTypeAdminList;
    mapping(ContractType => uint256) public currentAdminEpoch;

    mapping(ContractType => address) public contractAddressBook;
    mapping(ContractType => uint256) public creationTypeLimit;
    mapping(bytes32 => uint256) private _functionExpenseList;
    mapping(address => bool) public isContractTransferSwithOn;

    mapping(address => mapping(ContractType => address[]))
        private _creatorCreationList;
    mapping(ContractType => address[]) private _creationList;

    uint256[50] private __gap;

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
        bool swichOnStatus
    );

    modifier validAddressAndType(
        address targetAddress,
        ContractType targetType
    ) {
        require(targetAddress != address(0), "Invalid address");
        require(targetType != ContractType.UNDEFINED, "Invalid contractType");
        _;
    }

    modifier notUndefinedType(ContractType contractType) {
        require(contractType != ContractType.UNDEFINED, "Invalid contractType");
        _;
    }

    modifier onlyAdmin() {
        require(
            adminStatus[thisContractType][msg.sender],
            "Need AdminControlAdmin"
        );
        _;
    }

    modifier onlyFromContractInAddressBook() {
        require(
            contractAddressBook[ICRNGeneric(msg.sender).thisContractType()] ==
                msg.sender,
            "sender do not have authorization"
        );
        _;
    }

    modifier onlOriginalContract(address targetAddress) {
        require(
            _isOriginalContract(targetAddress),
            "contractAddress is not carina original contract"
        );
        _;
    }

    constructor() {
        _disableInitializers();
    }

    function initialize(
        address ownerAddress,
        address CRNAddress
    ) public initializer {
        __Ownable_init(ownerAddress);
        CONTRACTVERSION = "CARINA_ADMINCONTROL_V1.0.0";

        adminStatus[ContractType.ADMINCONTROL][ownerAddress] = true;
        _creationTypeAdminList[ContractType.ADMINCONTROL].push(ownerAddress);
        currentAdminEpoch[ContractType.ADMINCONTROL] = 1;

        adminStatus[ContractType.USERMANAGER_A][ownerAddress] = true;
        _creationTypeAdminList[ContractType.USERMANAGER_A].push(ownerAddress);
        currentAdminEpoch[ContractType.USERMANAGER_A] = 1;

        adminStatus[ContractType.POINTFACTORY][ownerAddress] = true;
        _creationTypeAdminList[ContractType.POINTFACTORY].push(ownerAddress);
        currentAdminEpoch[ContractType.POINTFACTORY] = 1;

        adminStatus[ContractType.MEMBERSHIPFACTORY][ownerAddress] = true;
        _creationTypeAdminList[ContractType.MEMBERSHIPFACTORY].push(
            ownerAddress
        );
        currentAdminEpoch[ContractType.MEMBERSHIPFACTORY] = 1;

        adminStatus[ContractType.ROUTER_A][ownerAddress] = true;
        _creationTypeAdminList[ContractType.ROUTER_A].push(ownerAddress);
        currentAdminEpoch[ContractType.ROUTER_A] = 1;

        adminStatus[ContractType.ROUTER_B][ownerAddress] = true;
        _creationTypeAdminList[ContractType.ROUTER_B].push(ownerAddress);
        currentAdminEpoch[ContractType.ROUTER_B] = 1;

        adminStatus[ContractType.POINT][ownerAddress] = true;
        _creationTypeAdminList[ContractType.POINT].push(ownerAddress);
        currentAdminEpoch[ContractType.POINT] = 1;

        adminStatus[ContractType.MEMBERSHIP][ownerAddress] = true;
        _creationTypeAdminList[ContractType.MEMBERSHIP].push(ownerAddress);
        currentAdminEpoch[ContractType.MEMBERSHIP] = 1;

        adminStatus[ContractType.CREDIT][ownerAddress] = true;
        _creationTypeAdminList[ContractType.CREDIT].push(ownerAddress);
        adminStatus[ContractType.CREDIT][address(this)] = true;
        _creationTypeAdminList[ContractType.CREDIT].push(address(this));
        currentAdminEpoch[ContractType.CREDIT] = 1;

        adminStatus[ContractType.WCRNCONVERTER][ownerAddress] = true;
        _creationTypeAdminList[ContractType.WCRNCONVERTER].push(ownerAddress);
        currentAdminEpoch[ContractType.WCRNCONVERTER] = 1;

        adminStatus[ContractType.WRAPPEDCRN][ownerAddress] = true;
        _creationTypeAdminList[ContractType.WRAPPEDCRN].push(ownerAddress);
        currentAdminEpoch[ContractType.WRAPPEDCRN] = 1;

        creationTypeLimit[ContractType.POINT] = 1;
        creationTypeLimit[ContractType.MEMBERSHIP] = 1;

        contractAddressBook[ContractType.ADMINCONTROL] = address(this);

        contractAddressBook[ContractType.CRNTOKEN] = CRNAddress;
    }

    function _updateContractAdmin(ContractType contractType) internal {
        if (uint8(contractType) > 8) {
            ICRNGeneric(contractAddressBook[contractType]).updateAdmin();
        }
    }

    function addAdmin(
        address addAdminAddress,
        ContractType contractType
    ) external onlyOwner validAddressAndType(addAdminAddress, contractType) {
        require(
            adminStatus[contractType][addAdminAddress] == false,
            "addAdminAddress already added"
        );
        adminStatus[contractType][addAdminAddress] = true;
        _creationTypeAdminList[contractType].push(addAdminAddress);
        currentAdminEpoch[contractType]++;
        _updateContractAdmin(contractType);
        emit AdminAddressAdded(contractType, addAdminAddress);
    }

    function removeAdmin(
        address removeAdminAddress,
        ContractType contractType
    ) external onlyOwner validAddressAndType(removeAdminAddress, contractType) {
        require(
            adminStatus[contractType][removeAdminAddress] == true,
            "removeAdminAddress is not in the Admin list"
        );
        adminStatus[contractType][removeAdminAddress] = false;
        for (uint i = 0; i < _creationTypeAdminList[contractType].length; i++) {
            if (_creationTypeAdminList[contractType][i] == removeAdminAddress) {
                _creationTypeAdminList[contractType][
                    i
                ] = _creationTypeAdminList[contractType][
                    _creationTypeAdminList[contractType].length - 1
                ];
                _creationTypeAdminList[contractType].pop();
                currentAdminEpoch[contractType]++;
                _updateContractAdmin(contractType);
                emit AdminAddressRemoved(contractType, removeAdminAddress);
                break;
            }
        }
    }

    function getAdminList(
        ContractType contractType
    ) external view notUndefinedType(contractType) returns (address[] memory) {
        return _creationTypeAdminList[contractType];
    }

    function setContractAddress(
        address contractAddress
    ) external onlyAdmin onlOriginalContract(contractAddress) {
        ContractType contractType = ICRNGeneric(contractAddress)
            .thisContractType();
        address previousContractAddress = contractAddressBook[contractType];
        require(
            contractAddress != previousContractAddress,
            "contractAddress already set"
        );
        contractAddressBook[contractType] = contractAddress;
        _updateContractAdmin(contractType);
        emit ContractAddressSet(
            contractType,
            previousContractAddress,
            contractAddress
        );
    }

    function setCreationLimit(
        ContractType targetType,
        uint256 newCreationLimitValue
    ) external onlyAdmin notUndefinedType(targetType) {
        uint256 previousCreationLimitValue = creationTypeLimit[targetType];
        require(
            newCreationLimitValue != previousCreationLimitValue,
            "newCreationLimitValue is same as now"
        );
        creationTypeLimit[targetType] = newCreationLimitValue;
        emit CreationLimitSet(
            targetType,
            previousCreationLimitValue,
            newCreationLimitValue
        );
    }

    function getFunctionExpense(
        address contractAddress,
        string calldata functionName
    ) external view onlOriginalContract(contractAddress) returns (uint256) {
        return
            _functionExpenseList[
                keccak256(abi.encodePacked(contractAddress, functionName))
            ];
    }

    function setFunctionExpense(
        address contractAddress,
        string calldata functionName,
        uint256 newExpenseValue
    ) external onlyAdmin onlOriginalContract(contractAddress) {
        bytes32 functionKey = keccak256(
            abi.encodePacked(contractAddress, functionName)
        );
        uint256 previousExpenseValue = _functionExpenseList[functionKey];
        require(
            newExpenseValue != previousExpenseValue,
            "newExpenseValue is same as now"
        );
        _functionExpenseList[functionKey] = newExpenseValue;
        emit FunctionExpenseSet(
            contractAddress,
            functionName,
            previousExpenseValue,
            newExpenseValue
        );
    }

    // function setFunctionExpenseBatch(
    //     address contractAddress,
    //     string[] calldata functionNameList,
    //     uint256[] calldata expenseValueList
    // ) external onlyAdmin onlOriginalContract(contractAddress) returns (bool) {
    //     require(
    //         functionNameList.length == expenseValueList.length,
    //         "expenseValueList not match to functionNameList"
    //     );
    //     for (uint i = 0; i < expenseValueList.length; i++) {
    //         uint256 currentExpenseValue = expenseValueList[i];
    //         string memory currentFuctionName = functionNameList[i];
    //         require(
    //             bytes(currentFuctionName).length > 0,
    //             "functionNameList include empty data"
    //         );
    //         bytes32 functionKey = keccak256(
    //             abi.encodePacked(contractAddress, currentFuctionName)
    //         );
    //         require(
    //             currentExpenseValue != _functionExpenseList[functionKey],
    //             "expenseValueList include same functionExpense value as current"
    //         );
    //         _functionExpenseList[functionKey] = currentExpenseValue;
    //     }
    //     return true;
    // }

    function isInsufficientCredit(
        address payerAddress,
        address contractAddress,
        string memory functionName
    ) external view returns (bool, uint256) {
        uint feeAmount = _functionExpenseList[
            keccak256(abi.encodePacked(contractAddress, functionName))
        ];
        return (
            ICRNGeneric(contractAddressBook[ContractType.CREDIT]).balanceOf(
                payerAddress
            ) < feeAmount,
            feeAmount
        );
    }

    function changeCreationTransferSwitch(
        address contractAddress,
        bool newSwichOnStatus
    ) external onlyAdmin onlOriginalContract(contractAddress) {
        require(newSwichOnStatus != isContractTransferSwithOn[contractAddress]);
        isContractTransferSwithOn[contractAddress] = newSwichOnStatus;
        ICRNGeneric(contractAddress).updateTransferSwitch();
        emit CreationTransferSwitchChanged(contractAddress, newSwichOnStatus);
    }

    function getCreatorCreationAddressList(
        address creatorAddress,
        ContractType targetType
    ) external view returns (address[] memory) {
        return _creatorCreationList[creatorAddress][targetType];
    }

    function _addToCreatorCreationList(
        address creatorAddress,
        ContractType contractType,
        address addCreationAddress
    ) internal {
        _creatorCreationList[creatorAddress][contractType].push(
            addCreationAddress
        );
    }

    function _removeFromCreatorCreationList(
        address creatorAddress,
        ContractType contractType,
        address removeCreationAddress
    ) internal {
        address[] storage addresses = _creatorCreationList[creatorAddress][
            contractType
        ];
        for (uint256 i = 0; i < addresses.length; i++) {
            if (addresses[i] == removeCreationAddress) {
                addresses[i] = addresses[addresses.length - 1];
                addresses.pop();
                break;
            }
        }
    }

    function getCreationAddressList(
        ContractType targetType
    ) external view returns (address[] memory) {
        return _creationList[targetType];
    }

    function whenCreationCreated(
        address creatorAddress,
        ContractType contractType,
        address creationAddress
    ) external onlyFromContractInAddressBook {
        _addToCreatorCreationList(
            creatorAddress,
            contractType,
            creationAddress
        );
        _creationList[contractType].push(creationAddress);
    }

    function whenCreatorChanged(
        address creationAddress,
        ContractType contractType,
        address previousCreator,
        address newCreator
    )
        external
        onlyFromContractInAddressBook
        validAddressAndType(newCreator, contractType)
    {
        _removeFromCreatorCreationList(
            previousCreator,
            contractType,
            creationAddress
        );
        _addToCreatorCreationList(newCreator, contractType, creationAddress);
    }

    function payExpense(
        address payerAddress,
        address contractAddress,
        string memory functionName
    ) external onlyFromContractInAddressBook returns (bool, uint256) {
        uint256 feeAmount = _functionExpenseList[
            keccak256(abi.encodePacked(contractAddress, functionName))
        ];
        if (feeAmount > 0) {
            ICRNGeneric(contractAddressBook[ContractType.CREDIT]).pTransfer(
                payerAddress,
                contractAddress,
                feeAmount
            );
        }
        return (true, feeAmount);
    }

    function isOverCreationTypeLimit(
        address creatorAddress,
        ContractType contractType
    )
        external
        view
        validAddressAndType(creatorAddress, contractType)
        returns (bool)
    {
        return
            _creatorCreationList[creatorAddress][contractType].length >=
            creationTypeLimit[contractType];
    }

    function _isOriginalContract(
        address targetAddress
    ) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(targetAddress)
        }
        if (size == 0) {
            return false;
        }
        try ICRNGeneric(targetAddress).thisContractType() returns (
            ContractType result
        ) {
            return uint8(result) > 0;
        } catch {
            return false;
        }
    }
}
