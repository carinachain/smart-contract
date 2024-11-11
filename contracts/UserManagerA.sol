// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./CRNAdmin.sol";

contract UserManagerA is Initializable, CRNAdmin {
    ContractType public constant thisContractType = ContractType.USERMANAGER_A;
    string public CONTRACTVERSION;

    struct AddressList {
        address[] FeeFree;
        address[] FeeSelfPay;
    }

    mapping(address => UserType) public userTypeInfo;
    mapping(address => AddressList) private groupStoresList;
    mapping(address => mapping(address => RelationType))
        public storeGroupRelationInfo;
    mapping(address => address) public storeToGroup;
    mapping(address => mapping(UserType => AddressList))
        private contractBusinessEntityList;
    mapping(address => mapping(address => RelationType))
        public contractBusinessEntityRelationInfo;
    mapping(address => mapping(ContractType => AddressList))
        private beOperatableContractsList;

    uint256[50] private __gap;

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

    // constructor (address adminControlAddress) CRNAdmin(adminControlAddress) {
    //     userTypeInfo[ICRNGeneric(adminControl).owner()] = UserType.ADMINISTRATOR;
    // }

    constructor() {
        _disableInitializers();
    }

    function initialize(address adminControlAddress) public initializer {
        adminControl = adminControlAddress;
        userTypeInfo[ICRNGeneric(adminControl).owner()] = UserType
            .ADMINISTRATOR;
        CONTRACTVERSION = "CARINA_USERMANAGER_A_V1.0.0";
    }

    function checkManageUserType(
        address userAddress,
        UserType userType
    ) public view returns (bool, string memory) {
        if (userAddress == address(0)) {
            return (false, "userAddress cannot be zero");
        }
        if (userType == UserType.UNREGISTERED) {
            return (false, "userType cannot be UNREGISTERED");
        }
        if (userTypeInfo[userAddress] == UserType.DELETED) {
            return (false, "Deleted user cannot set");
        } else if (userTypeInfo[userAddress] == UserType.UNREGISTERED) {
            if (userType == UserType.DELETED) {
                return (false, "Can not set UNREGISTERED user to DELETED");
            }
        } else if (userType != UserType.DELETED) {
            return (false, "UserType already set, cannot be modified");
        }
        return (true, "");
    }

    function manageUserType(
        address userAddress,
        UserType userType
    ) external onlyAdmin returns (bool) {
        (bool checkResult, string memory errorMessage) = checkManageUserType(
            userAddress,
            userType
        );
        require(checkResult, errorMessage);

        userTypeInfo[userAddress] = userType;
        emit UserSet(userAddress, userType);
        return true;
    }

    function getGroupStoresList(
        address groupAddress
    ) external view returns (address[] memory, address[] memory) {
        return (
            groupStoresList[groupAddress].FeeFree,
            groupStoresList[groupAddress].FeeSelfPay
        );
    }

    function _addToGroupStoresList(
        address groupAddress,
        address storeAddress,
        RelationType relationType
    ) internal {
        if (relationType == RelationType.FEEFREE) {
            groupStoresList[groupAddress].FeeFree.push(storeAddress);
        }
        if (relationType == RelationType.FEESELFPAY) {
            groupStoresList[groupAddress].FeeSelfPay.push(storeAddress);
        }
    }

    function _removeFromGroupStoresList(
        address groupAddress,
        address storeAddress
    ) internal {
        address[] storage addresses;
        if (
            storeGroupRelationInfo[storeAddress][groupAddress] ==
            RelationType.FEEFREE
        ) {
            addresses = groupStoresList[groupAddress].FeeFree;
        } else if (
            storeGroupRelationInfo[storeAddress][groupAddress] ==
            RelationType.FEESELFPAY
        ) {
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
    ) public view returns (bool, string memory) {
        if (userTypeInfo[groupAddress] != UserType.GROUP) {
            return (false, "groupAddress UserType must be GROUP");
        }
        if (userTypeInfo[storeAddress] != UserType.STORE) {
            return (false, "storeAddress UserType must be STORE");
        }
        if (relationType == RelationType.UNDEFINED) {
            return (false, "relationType cannot be UNDEFINED");
        }
        if (
            (relationType == RelationType.CLEARED &&
                uint8(storeGroupRelationInfo[storeAddress][groupAddress]) <= 1)
        ) {
            return (false, "Cannot change UNDEFINED/CLEARED to CLEARED");
        }
        if (
            relationType == storeGroupRelationInfo[storeAddress][groupAddress]
        ) {
            return (false, "relationType is same value as current");
        }
        if (
            storeToGroup[storeAddress] != groupAddress &&
            storeToGroup[storeAddress] != address(0)
        ) {
            return (false, "Store already joined another group");
        }
        return (true, "");
    }

    function manageGroupStore(
        address groupAddress,
        address storeAddress,
        RelationType relationType
    ) external onlyAdmin returns (bool) {
        (bool checkResult, string memory errorMessage) = checkManageGroupStore(
            groupAddress,
            storeAddress,
            relationType
        );
        require(checkResult, errorMessage);

        RelationType previousRelationType = storeGroupRelationInfo[
            storeAddress
        ][groupAddress];
        if (uint8(previousRelationType) > 1) {
            _removeFromGroupStoresList(groupAddress, storeAddress);
        }
        if (relationType == RelationType.CLEARED) {
            storeToGroup[storeAddress] = address(0);
        } else {
            storeToGroup[storeAddress] = groupAddress;
            _addToGroupStoresList(groupAddress, storeAddress, relationType);
        }
        storeGroupRelationInfo[storeAddress][groupAddress] = relationType;

        emit GroupStoreRelationChanged(
            groupAddress,
            storeAddress,
            previousRelationType,
            relationType
        );
        return true;
    }

    function _removeFromBEOperatableContractsList(
        address businessEntityAddress,
        address removeContractAddress,
        ContractType contractType
    ) internal {
        RelationType typeValue = contractBusinessEntityRelationInfo[
            removeContractAddress
        ][businessEntityAddress];
        address[] storage addresses;
        if (typeValue == RelationType.FEEFREE) {
            addresses = beOperatableContractsList[businessEntityAddress][
                contractType
            ].FeeFree;
        } else if (typeValue == RelationType.FEESELFPAY) {
            addresses = beOperatableContractsList[businessEntityAddress][
                contractType
            ].FeeSelfPay;
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
    ) external view returns (address[] memory, address[] memory) {
        return (
            contractBusinessEntityList[contractAddress][userTypeValue].FeeFree,
            contractBusinessEntityList[contractAddress][userTypeValue]
                .FeeSelfPay
        );
    }

    function _removeFromContractBEList(
        address contractAddress,
        address removeTargetAddress
    ) internal {
        address[] storage addresses;
        if (
            contractBusinessEntityRelationInfo[contractAddress][
                removeTargetAddress
            ] == RelationType.FEEFREE
        ) {
            addresses = contractBusinessEntityList[contractAddress][
                userTypeInfo[removeTargetAddress]
            ].FeeFree;
        } else if (
            contractBusinessEntityRelationInfo[contractAddress][
                removeTargetAddress
            ] == RelationType.FEESELFPAY
        ) {
            addresses = contractBusinessEntityList[contractAddress][
                userTypeInfo[removeTargetAddress]
            ].FeeSelfPay;
        } else {
            revert();
        }

        for (uint256 i = 0; i < addresses.length; i++) {
            if (addresses[i] == removeTargetAddress) {
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
    ) public view returns (bool, string memory) {
        if (senderAddress != ICRNGeneric(contractAddress).creator()) {
            return (false, "senderAddress is not contract creator");
        }
        if (uint8(userTypeInfo[businessEntityAddress]) <= 2) {
            return (
                false,
                "businessEntityAddress UserType do not have permission"
            );
        }
        if (targetType == RelationType.UNDEFINED) {
            return (false, "targetType cannot be UNDEFINED");
        }
        if (
            (targetType == RelationType.CLEARED &&
                uint8(
                    contractBusinessEntityRelationInfo[contractAddress][
                        businessEntityAddress
                    ]
                ) <=
                1)
        ) {
            return (false, "Cannot change UNDEFINED/CLEARED to CLEARED");
        }
        if (
            targetType ==
            contractBusinessEntityRelationInfo[contractAddress][
                businessEntityAddress
            ]
        ) {
            return (false, "targetType is same value as current");
        }
        if (
            targetType ==
            storeGroupRelationInfo[businessEntityAddress][
                ICRNGeneric(contractAddress).creator()
            ] &&
            targetType != RelationType.CLEARED
        ) {
            return (
                false,
                "businessEntityAddress already has same permission from parent group"
            );
        }
        return (true, "");
    }

    function manageContractBE(
        address senderAddress,
        address contractAddress,
        address businessEntityAddress,
        RelationType targetType
    ) external onlyAdmin returns (bool) {
        (bool result, string memory errorMessage) = checkManageContractBE(
            senderAddress,
            contractAddress,
            businessEntityAddress,
            targetType
        );
        require(result, errorMessage);

        RelationType previousRelationType = contractBusinessEntityRelationInfo[
            contractAddress
        ][businessEntityAddress];
        ContractType contractType = ICRNGeneric(contractAddress)
            .thisContractType();

        if (uint8(previousRelationType) > 1) {
            _removeFromBEOperatableContractsList(
                businessEntityAddress,
                contractAddress,
                contractType
            );
            _removeFromContractBEList(contractAddress, businessEntityAddress);
        }
        if (targetType == RelationType.FEEFREE) {
            beOperatableContractsList[businessEntityAddress][contractType]
                .FeeFree
                .push(contractAddress);
            contractBusinessEntityList[contractAddress][
                userTypeInfo[businessEntityAddress]
            ].FeeFree.push(businessEntityAddress);
        } else if (targetType == RelationType.FEESELFPAY) {
            beOperatableContractsList[businessEntityAddress][contractType]
                .FeeSelfPay
                .push(contractAddress);
            contractBusinessEntityList[contractAddress][
                userTypeInfo[businessEntityAddress]
            ].FeeSelfPay.push(businessEntityAddress);
        }
        contractBusinessEntityRelationInfo[contractAddress][
            businessEntityAddress
        ] = targetType;

        emit ContractBusinessEntityChanged(
            contractAddress,
            businessEntityAddress,
            previousRelationType,
            targetType
        );
        return true;
    }

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
        )
    {
        address targetToGroupAddress = storeToGroup[targetAddress];
        return (
            ICRNGeneric(adminControl).getCreatorCreationAddressList(
                targetAddress,
                targetType
            ),
            ICRNGeneric(adminControl).getCreatorCreationAddressList(
                targetToGroupAddress,
                targetType
            ),
            beOperatableContractsList[targetAddress][targetType].FeeFree,
            beOperatableContractsList[targetAddress][targetType].FeeSelfPay,
            beOperatableContractsList[targetToGroupAddress][targetType].FeeFree,
            beOperatableContractsList[targetToGroupAddress][targetType]
                .FeeSelfPay
        );
    }

    function checkSenderPermission(
        address contractAddress,
        address senderAddress
    ) external view returns (bool) {
        address contractCreator = ICRNGeneric(contractAddress).creator();
        address senderGroupAddress = storeToGroup[senderAddress];

        return (contractCreator == senderGroupAddress ||
            contractCreator == senderAddress ||
            uint8(
                contractBusinessEntityRelationInfo[contractAddress][
                    senderAddress
                ]
            ) >
            1 ||
            uint8(
                contractBusinessEntityRelationInfo[contractAddress][
                    senderGroupAddress
                ]
            ) >
            1);
    }

    function getPayerAddress(
        address contractAddress,
        address senderAddress
    ) external view returns (address) {
        address payerAddress = senderAddress;
        address contractCreator = ICRNGeneric(contractAddress).creator();
        address senderGroupAddress = storeToGroup[senderAddress];

        if (
            storeGroupRelationInfo[senderAddress][contractCreator] ==
            RelationType.FEEFREE ||
            contractBusinessEntityRelationInfo[contractAddress][
                senderGroupAddress
            ] ==
            RelationType.FEEFREE ||
            contractBusinessEntityRelationInfo[contractAddress][
                senderAddress
            ] ==
            RelationType.FEEFREE
        ) {
            payerAddress = contractCreator;
        } else if (
            contractBusinessEntityRelationInfo[contractAddress][
                senderGroupAddress
            ] ==
            RelationType.FEESELFPAY &&
            storeGroupRelationInfo[senderAddress][senderGroupAddress] ==
            RelationType.FEEFREE
        ) {
            payerAddress = senderGroupAddress;
        }
        return payerAddress;
    }

    function updateAdmin() external {
        _updateAdmin(thisContractType);
    }
}
