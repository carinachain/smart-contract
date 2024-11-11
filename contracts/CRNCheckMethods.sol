// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./CRNAdmin.sol";

abstract contract CRNCheckMethods is CRNAdmin {
    address public userManagerA;

    event UserManagerAUpdated(
        address indexed previousUserManagerA,
        address indexed newUserManagerA
    );

    modifier onlOriginalContract(address targetAddress) {
        require(
            _isOriginalContract(targetAddress),
            "contractAddress is not carina original contract"
        );
        _;
    }

    // constructor (address adminControlAddress) {
    //     userManagerA = ICRNGeneric(adminControl).contractAddressBook(ContractType.USERMANAGER_A);
    // }

    function _isOriginalContract(
        address targetAddress
    ) internal view virtual returns (bool) {
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

    function _isRegisteredUser(
        address targetAddress
    ) internal view virtual returns (bool) {
        return uint8(ICRNGeneric(userManagerA).userTypeInfo(targetAddress)) > 1;
    }

    function _isBusinessUser(
        address targetAddress
    ) internal view virtual returns (bool) {
        return uint8(ICRNGeneric(userManagerA).userTypeInfo(targetAddress)) > 2;
    }

    function _isOverCreationTypeLimit(
        address creatorAddress,
        ContractType targetType
    ) internal view virtual returns (bool) {
        return
            ICRNGeneric(adminControl).isOverCreationTypeLimit(
                creatorAddress,
                targetType
            );
    }

    function _isOverDistributeLimit(
        address contractAddress,
        uint256 amount
    ) internal view virtual returns (bool) {
        return amount > ICRNGeneric(contractAddress).distributeLimit();
    }

    function _checkSenderPermission(
        address contractAddress,
        address senderAddress
    ) internal view virtual returns (bool) {
        return
            ICRNGeneric(userManagerA).checkSenderPermission(
                contractAddress,
                senderAddress
            );
    }

    function _hasEnoughBalance(
        address contractAddress,
        address targetAddress,
        uint256 amount
    ) internal view virtual returns (bool) {
        return amount <= ICRNGeneric(contractAddress).balanceOf(targetAddress);
    }

    function _isContractCreator(
        address contractAddress,
        address targetAddress
    ) internal view virtual returns (bool) {
        return targetAddress == ICRNGeneric(contractAddress).creator();
    }

    function _isSameDistributeLimit(
        address contractAddress,
        uint256 targetValue
    ) internal view virtual returns (bool) {
        return targetValue == ICRNGeneric(contractAddress).distributeLimit();
    }

    function _isSamePausedStatus(
        address contractAddress,
        bool targetValue
    ) internal view virtual returns (bool) {
        return targetValue == ICRNGeneric(contractAddress).paused();
    }

    function _canManageContractBE(
        address senderAddress,
        address contractAddress,
        address businessEntityAddress,
        RelationType targetType
    ) internal view virtual returns (bool, string memory) {
        return
            ICRNGeneric(userManagerA).checkManageContractBE(
                senderAddress,
                contractAddress,
                businessEntityAddress,
                targetType
            );
    }

    function updateUserManager() public {
        address newUserManagerA = ICRNGeneric(adminControl).contractAddressBook(
            ContractType.USERMANAGER_A
        );
        address previousUserManagerAddress = userManagerA;
        require(
            newUserManagerA != previousUserManagerAddress,
            "No need update adminControl"
        );
        userManagerA = newUserManagerA;
        emit UserManagerAUpdated(previousUserManagerAddress, newUserManagerA);
    }

    function _isStringEmpty(
        string memory str
    ) internal view virtual returns (bool) {
        return bytes(str).length == 0;
    }

    function _isStringSame(
        string memory str1,
        string memory str2
    ) internal view virtual returns (bool) {
        return
            keccak256(abi.encodePacked(str1)) ==
            keccak256(abi.encodePacked(str2));
    }
}
