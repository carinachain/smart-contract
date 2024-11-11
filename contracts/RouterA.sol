// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./CRNBusinessModule.sol";

contract RouterA is Initializable, CRNBusinessModule {
    ContractType public constant thisContractType = ContractType.ROUTER_A;
    string public CONTRACTVERSION;

    uint256[50] private __gap;

    event UserTypeChanged(
        address indexed senderAddress,
        UserType indexed newUserType
    );
    event GroupStoreRelationChanged(
        address indexed groupAddress,
        address indexed storeAddress,
        RelationType indexed targetRelation
    );
    event ContractBERelationChanged(
        address indexed contractAddress,
        address indexed businessEntityAddress,
        RelationType indexed targetRelation
    );
    event ContractCreatorChanged(
        address indexed contractAddress,
        address indexed previousCreator,
        address indexed newCreator
    );
    event ContractPausedStatusChanged(
        address indexed contractAddress,
        bool indexed newPausedStatus
    );
    event ContractDistributeLimitChanged(
        address indexed contractAddress,
        uint256 newDistributeLimit
    );
    event ContractLevelDefinationChanged(
        address indexed contractAddress,
        uint256 indexed levelNumber,
        string newlevelName
    );

    constructor() {
        _disableInitializers();
    }

    function initialize(address adminControlAddress) public initializer {
        adminControl = adminControlAddress;
        userManagerA = ICRNGeneric(adminControl).contractAddressBook(
            ContractType.USERMANAGER_A
        );
        CONTRACTVERSION = "CARINA_ROUTER_A_V1.0.0";
    }

    function updateAdmin() external {
        _updateAdmin(thisContractType);
    }

    function checkManageUserRegistration(
        address userAddress,
        UserType userType
    ) public view returns (bool, string memory) {
        return
            ICRNGeneric(userManagerA).checkManageUserType(
                userAddress,
                userType
            );
    }

    function manageUserRegistration(
        address userAddress,
        UserType userType
    ) external onlyAdmin {
        require(
            ICRNGeneric(userManagerA).manageUserType(userAddress, userType),
            "manageUserRegistration failed"
        );
        emit UserTypeChanged(userAddress, userType);
    }

    function checkManageGroupStore(
        address groupAddress,
        address storeAddress,
        RelationType relationType
    ) public view returns (bool, string memory, address, uint256) {
        (bool creditBalanceCheck, uint256 feeAmount) = _isInsufficientCredit(
            groupAddress,
            "manageGroupStore"
        );
        if (creditBalanceCheck) {
            return (
                false,
                "groupAddress insufficient credit",
                groupAddress,
                feeAmount
            );
        }
        (bool check, string memory errorMessage) = ICRNGeneric(userManagerA)
            .checkManageGroupStore(groupAddress, storeAddress, relationType);
        if (!check) {
            return (false, errorMessage, groupAddress, feeAmount);
        }
        return (true, "", groupAddress, feeAmount);
    }

    function manageGroupStore(
        address groupAddress,
        address storeAddress,
        RelationType relationType
    ) external onlyAdmin returns (address, uint256) {
        require(
            ICRNGeneric(userManagerA).manageGroupStore(
                groupAddress,
                storeAddress,
                relationType
            ),
            "manageGroupStore failed"
        );
        emit GroupStoreRelationChanged(
            groupAddress,
            storeAddress,
            relationType
        );
        return (groupAddress, _payFee(groupAddress, "manageGroupStore"));
    }

    function checkManageContractBE(
        address senderAddress,
        address contractAddress,
        address businessEntityAddress,
        RelationType targetType
    ) public view returns (bool, string memory, address, uint256) {
        (bool creditBalanceCheck, uint256 feeAmount) = _isInsufficientCredit(
            senderAddress,
            "manageContractBE"
        );
        if (creditBalanceCheck) {
            return (
                false,
                "senderAddress insufficient credit",
                senderAddress,
                feeAmount
            );
        }
        if (!_isOriginalContract(contractAddress)) {
            return (
                false,
                "contractAddress is not carina original contract",
                senderAddress,
                feeAmount
            );
        } else {
            (bool check, string memory errorMessage) = ICRNGeneric(userManagerA)
                .checkManageContractBE(
                    senderAddress,
                    contractAddress,
                    businessEntityAddress,
                    targetType
                );
            if (!check) {
                return (false, errorMessage, senderAddress, feeAmount);
            }
        }
        return (true, "", senderAddress, feeAmount);
    }

    function manageContractBE(
        address senderAddress,
        address contractAddress,
        address businessEntityAddress,
        RelationType targetType
    )
        external
        onlyAdmin
        onlOriginalContract(contractAddress)
        returns (address, uint256)
    {
        require(
            ICRNGeneric(userManagerA).manageContractBE(
                senderAddress,
                contractAddress,
                businessEntityAddress,
                targetType
            ),
            "manageContractBE failed"
        );
        emit ContractBERelationChanged(
            contractAddress,
            businessEntityAddress,
            targetType
        );
        return (senderAddress, _payFee(senderAddress, "manageContractBE"));
    }

    function checkChangeContractCreator(
        address contractAddress,
        address senderAddress,
        address newCreator
    ) public view returns (bool, string memory, address, uint256) {
        (bool creditBalanceCheck, uint256 feeAmount) = _isInsufficientCredit(
            senderAddress,
            "changeContractCreator"
        );
        if (creditBalanceCheck) {
            return (
                false,
                "senderAddress insufficient credit",
                senderAddress,
                feeAmount
            );
        }

        if (!_isOriginalContract(contractAddress)) {
            return (
                false,
                "contractAddress is not carina original contract",
                senderAddress,
                feeAmount
            );
        } else {
            if (!_isContractCreator(contractAddress, senderAddress)) {
                return (
                    false,
                    "senderAddress is not contract creator",
                    senderAddress,
                    feeAmount
                );
            }
            if (!_isBusinessUser(newCreator)) {
                return (
                    false,
                    "newCreator must be business user",
                    senderAddress,
                    feeAmount
                );
            }
            if (
                _isOverCreationTypeLimit(
                    newCreator,
                    ICRNGeneric(contractAddress).thisContractType()
                )
            ) {
                return (
                    false,
                    "newCreator Reached creation limit",
                    senderAddress,
                    feeAmount
                );
            }
        }
        return (true, "", senderAddress, feeAmount);
    }

    function changeContractCreator(
        address contractAddress,
        address senderAddress,
        address newCreator
    )
        external
        onlyAdmin
        onlOriginalContract(contractAddress)
        returns (address, uint256)
    {
        require(
            _isBusinessUser(newCreator),
            "newCreator must be business user"
        );
        ContractType contractType = ICRNGeneric(contractAddress)
            .thisContractType();
        require(
            !_isOverCreationTypeLimit(newCreator, contractType),
            "newCreator Reached creation limit"
        );
        require(
            ICRNGeneric(contractAddress).changeCreator(
                senderAddress,
                newCreator
            ),
            "changeContractCreator failed"
        );
        ICRNGeneric(adminControl).whenCreatorChanged(
            contractAddress,
            contractType,
            senderAddress,
            newCreator
        );
        emit ContractCreatorChanged(contractAddress, senderAddress, newCreator);
        return (senderAddress, _payFee(senderAddress, "changeContractCreator"));
    }

    function checkChangeContractPausedStatus(
        address contractAddress,
        address senderAddress,
        bool newValue
    ) public view returns (bool, string memory, address, uint256) {
        (bool creditBalanceCheck, uint256 feeAmount) = _isInsufficientCredit(
            senderAddress,
            "changeContractPausedStatus"
        );
        if (creditBalanceCheck) {
            return (
                false,
                "senderAddress insufficient credit",
                senderAddress,
                feeAmount
            );
        }

        if (!_isOriginalContract(contractAddress)) {
            return (
                false,
                "contractAddress is not carina original contract",
                senderAddress,
                feeAmount
            );
        } else {
            if (!_isContractCreator(contractAddress, senderAddress)) {
                return (
                    false,
                    "senderAddress is not contract creator",
                    senderAddress,
                    feeAmount
                );
            }
            if (_isSamePausedStatus(contractAddress, newValue)) {
                return (
                    false,
                    "newValue is same as now",
                    senderAddress,
                    feeAmount
                );
            }
        }
        return (true, "", senderAddress, feeAmount);
    }

    function changeContractPausedStatus(
        address contractAddress,
        address senderAddress,
        bool newValue
    )
        external
        onlyAdmin
        onlOriginalContract(contractAddress)
        returns (address, uint256)
    {
        require(
            ICRNGeneric(contractAddress).changePauseStatus(
                senderAddress,
                newValue
            ),
            "changeContractPausedStatus failed"
        );
        emit ContractPausedStatusChanged(contractAddress, newValue);
        return (
            senderAddress,
            _payFee(senderAddress, "changeContractPausedStatus")
        );
    }

    function checkChangeContractDistributeLimit(
        address contractAddress,
        address senderAddress,
        uint256 newValue
    ) public view returns (bool, string memory, address, uint256) {
        (bool creditBalanceCheck, uint256 feeAmount) = _isInsufficientCredit(
            senderAddress,
            "changeContractDistributeLimit"
        );
        if (creditBalanceCheck) {
            return (
                false,
                "senderAddress insufficient credit",
                senderAddress,
                feeAmount
            );
        }

        ContractType contractType = ICRNGeneric(contractAddress)
            .thisContractType();
        if (!_isOriginalContract(contractAddress)) {
            return (
                false,
                "contractAddress is not carina original contract",
                senderAddress,
                feeAmount
            );
        } else {
            if (contractType != ContractType.POINT) {
                return (
                    false,
                    "ContractType not support",
                    senderAddress,
                    feeAmount
                );
            }
            if (!_isContractCreator(contractAddress, senderAddress)) {
                return (
                    false,
                    "senderAddress is not contract creator",
                    senderAddress,
                    feeAmount
                );
            }
            if (_isSameDistributeLimit(contractAddress, newValue)) {
                return (
                    false,
                    "newValue is same as now",
                    senderAddress,
                    feeAmount
                );
            }
        }
        return (true, "", senderAddress, feeAmount);
    }

    function changeContractDistributeLimit(
        address contractAddress,
        address senderAddress,
        uint256 newValue
    )
        external
        onlyAdmin
        onlOriginalContract(contractAddress)
        returns (address, uint256)
    {
        require(
            ICRNGeneric(contractAddress).setDistributeLimit(
                senderAddress,
                newValue
            ),
            "changeContractDistributeLimit failed"
        );
        emit ContractDistributeLimitChanged(contractAddress, newValue);
        return (
            senderAddress,
            _payFee(senderAddress, "changeContractDistributeLimit")
        );
    }

    function checkMemberLevelDefine(
        address contractAddress,
        address senderAddress,
        uint256 level,
        string memory targetlevelName
    ) public view returns (bool, string memory, address, uint256) {
        (bool creditBalanceCheck, uint256 feeAmount) = _isInsufficientCredit(
            senderAddress,
            "memberLevelDefinition"
        );
        if (creditBalanceCheck) {
            return (
                false,
                "senderAddress insufficient credit",
                senderAddress,
                feeAmount
            );
        }

        if (!_isOriginalContract(contractAddress)) {
            return (
                false,
                "contractAddress is not carina original contract",
                senderAddress,
                feeAmount
            );
        } else {
            if (level == 0) {
                return (
                    false,
                    "levelNumber can not be zero",
                    senderAddress,
                    feeAmount
                );
            }
            if (_isStringEmpty(targetlevelName)) {
                return (
                    false,
                    "targetlevelName can not be empty",
                    senderAddress,
                    feeAmount
                );
            }
            if (
                ICRNGeneric(contractAddress).thisContractType() !=
                ContractType.MEMBERSHIP
            ) {
                return (
                    false,
                    "ContractType not support",
                    senderAddress,
                    feeAmount
                );
            }
            if (!_isContractCreator(contractAddress, senderAddress)) {
                return (
                    false,
                    "senderAddress is not contract creator",
                    senderAddress,
                    feeAmount
                );
            }
            if (
                _isStringSame(
                    targetlevelName,
                    ICRNGeneric(contractAddress).levelName(level)
                )
            ) {
                return (
                    false,
                    "levelNumber is already be defined by same levelName",
                    senderAddress,
                    feeAmount
                );
            }
        }
        return (true, "", senderAddress, feeAmount);
    }

    function memberLevelDefinition(
        address contractAddress,
        address senderAddress,
        uint256 level,
        string memory targetlevelName
    )
        external
        onlyAdmin
        onlOriginalContract(contractAddress)
        returns (address, uint256)
    {
        require(
            ICRNGeneric(contractAddress).defineLevel(
                senderAddress,
                level,
                targetlevelName
            ),
            "memberLevelDefinition failed"
        );
        emit ContractLevelDefinationChanged(
            contractAddress,
            level,
            targetlevelName
        );
        return (senderAddress, _payFee(senderAddress, "memberLevelDefinition"));
    }

    function memberLevelDefinitionBatch(
        address contractAddress,
        address senderAddress,
        uint256[] calldata levelNumberArray,
        string[] calldata levelNameList
    )
        external
        onlyAdmin
        onlOriginalContract(contractAddress)
        returns (address, uint256)
    {
        require(
            ICRNGeneric(contractAddress).defineLevelBatch(
                senderAddress,
                levelNumberArray,
                levelNameList
            ),
            "memberLevelDefinitionBatch failed"
        );
        emit ContractLevelDefinationChanged(contractAddress, 0, "");
        return (
            senderAddress,
            _payFee(senderAddress, "memberLevelDefinitionBatch")
        );
    }
}
