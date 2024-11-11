// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./interfaces/ICRNGeneric.sol";

abstract contract CRNAdmin {
    string public constant COPYRIGHT =
        "Copyright (c) 2024 CarinaChain.com All rights reserved.";
    string public constant DEV = "NebulaInfinity.com";

    address public adminControl;

    mapping(address => uint256) private _adminList;
    uint256 public currentEpoch;

    event AdminControlUpdated(
        address indexed previousControl,
        address indexed newControl
    );
    event AdminUpdated(
        address indexed adminControlAddress,
        uint256 updatedEpoch
    );

    // constructor (address adminControlAddress){
    //     adminControl = adminControlAddress;
    // }

    modifier onlyAdmin() {
        require(_isThisAdmin(msg.sender), "Need this contract admin");
        _;
    }

    function _isThisAdmin(address target) internal view returns (bool) {
        return _adminList[target] == currentEpoch;
    }

    function updateAdminControl() public {
        address newControlAddress = ICRNGeneric(adminControl)
            .contractAddressBook(ContractType.ADMINCONTROL);
        address previousControlAddress = adminControl;
        require(
            newControlAddress != previousControlAddress,
            "No need update adminControl"
        );
        adminControl = newControlAddress;
        emit AdminControlUpdated(previousControlAddress, newControlAddress);
    }

    function _updateAdmin(ContractType thisContractType) internal {
        uint256 newEpoch = ICRNGeneric(adminControl).currentAdminEpoch(
            thisContractType
        );
        require(currentEpoch < newEpoch, "No need update admin");
        address[] memory newAdminAdressList = ICRNGeneric(adminControl)
            .getAdminList(thisContractType);
        for (uint256 i = 0; i < newAdminAdressList.length; i++) {
            _adminList[newAdminAdressList[i]] = newEpoch;
        }
        currentEpoch = newEpoch;
        emit AdminUpdated(adminControl, newEpoch);
    }
}
