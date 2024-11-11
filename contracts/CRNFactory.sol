// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./CRNAdmin.sol";

abstract contract CRNFactory is CRNAdmin {
    mapping(address => address[]) internal  _SenderCreatedContractList;

    function _isOverCreationTypeLimit(
        address creatorAddress,
        ContractType contractType
    ) internal view  returns (bool) {
        return ICRNGeneric(adminControl).isOverCreationTypeLimit(creatorAddress, contractType);
    }

    function getSenderCreatedContractList(address targetAddress) external view returns (address[] memory){
        return _SenderCreatedContractList[targetAddress];
    }

}