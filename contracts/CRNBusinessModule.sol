// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./CRNCheckMethods.sol";

abstract contract CRNBusinessModule is CRNCheckMethods {
    // constructor(address adminControlAddress) {
    //     adminControl = adminControlAddress;
    //     userManagerA = ICRNGeneric(adminControl).contractAddressBook(
    //         ContractType.USERMANAGER_A
    //     );
    // }

    function _payFee(
        address payerAddress,
        string memory functionName
    ) internal returns (uint256) {
        require(payerAddress != address(0), "payerAddress can not be Zero");
        (bool result, uint256 feeAmount) = ICRNGeneric(adminControl).payExpense(
            payerAddress,
            address(this),
            functionName
        );
        require(result, "Fee payment failed");
        return feeAmount;
    }

    function _getCreditPayer(
        address contractAddress,
        address senderAddress
    ) internal view virtual returns (address) {
        return
            ICRNGeneric(userManagerA).getPayerAddress(
                contractAddress,
                senderAddress
            );
    }

    function _isInsufficientCredit(
        address targetAddress,
        string memory functionName
    ) internal view virtual returns (bool, uint256) {
        return
            ICRNGeneric(adminControl).isInsufficientCredit(
                targetAddress,
                address(this),
                functionName
            );
    }
}
