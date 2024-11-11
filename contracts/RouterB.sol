// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./CRNBusinessModule.sol";

contract RouterB is Initializable, CRNBusinessModule {
    ContractType public constant thisContractType = ContractType.ROUTER_B;
    string public CONTRACTVERSION;

    address public pointFactory;
    address public membershipFactory;

    uint256[50] private __gap;

    event ContractCreated(
        ContractType indexed contractType,
        address indexed newCreationAddress,
        address indexed creatorAddress
    );
    event Distributed(
        address indexed contractAddress,
        address indexed senderAddress,
        address indexed userAddress,
        uint256 amount
    );
    event Deducted(
        address indexed contractAddress,
        address indexed senderAddress,
        address indexed userAddress,
        uint256 amount
    );
    event userTransferred(
        address indexed contractAddress,
        address indexed fromAddress,
        address indexed toAddress,
        uint256 amount
    );
    event MembershipIssued(
        address indexed contractAddress,
        address indexed senderAddress,
        address indexed memberAddress
    );
    event MembershipRevoked(
        address indexed contractAddress,
        address indexed senderAddress,
        address indexed memberAddress
    );
    event MemberLevelChanged(
        address indexed contractAddress,
        address indexed senderAddress,
        address indexed memberAddress
    );

    constructor() {
        _disableInitializers();
    }

    function initialize(address adminControlAddress) public initializer {
        adminControl = adminControlAddress;
        userManagerA = ICRNGeneric(adminControl).contractAddressBook(
            ContractType.USERMANAGER_A
        );
        pointFactory = ICRNGeneric(adminControl).contractAddressBook(
            ContractType.POINTFACTORY
        );
        membershipFactory = ICRNGeneric(adminControl).contractAddressBook(
            ContractType.MEMBERSHIPFACTORY
        );
        CONTRACTVERSION = "CARINA_ROUTER_B_V1.0.0";
    }

    function checkCreateInFactory(
        address creatorAddress,
        ContractType targetType,
        string calldata functionName
    ) public view returns (bool, string memory, address, uint256) {
        (bool creditBalanceCheck, uint256 feeAmount) = _isInsufficientCredit(
            creatorAddress,
            functionName
        );

        if (creditBalanceCheck) {
            return (
                false,
                "creatorAddress insufficient credit",
                creatorAddress,
                feeAmount
            );
        }
        if (!_isBusinessUser(creatorAddress)) {
            return (
                false,
                "creatorAddress must be business user",
                creatorAddress,
                feeAmount
            );
        }
        if (_isOverCreationTypeLimit(creatorAddress, targetType)) {
            return (
                false,
                "creatorAddress reached create limit",
                creatorAddress,
                feeAmount
            );
        }
        return (true, "", creatorAddress, feeAmount);
    }

    function createPoint(
        address creatorAddress,
        string calldata name,
        string calldata symbol,
        uint8 decimals
    ) external onlyAdmin returns (address, uint256) {
        require(
            _isBusinessUser(creatorAddress),
            "creatorAddress must be business user"
        );
        address newCreationAddress = ICRNGeneric(pointFactory).createPoint(
            creatorAddress,
            name,
            symbol,
            decimals
        );
        emit ContractCreated(
            ContractType.POINT,
            newCreationAddress,
            creatorAddress
        );
        return (creatorAddress, _payFee(creatorAddress, "createPoint"));
    }

    function createMembership(
        address creatorAddress
    ) external onlyAdmin returns (address, uint256) {
        require(
            _isBusinessUser(creatorAddress),
            "creatorAddress must be business user"
        );
        address newCreationAddress = ICRNGeneric(membershipFactory)
            .createMembership(creatorAddress);
        emit ContractCreated(
            ContractType.MEMBERSHIP,
            newCreationAddress,
            creatorAddress
        );
        return (creatorAddress, _payFee(creatorAddress, "createMembership"));
    }

    function checkDistribution(
        address contractAddress,
        address senderAddress,
        uint256 amount
    ) public view returns (bool, string memory, address, uint256) {
        address payerAddress = _getCreditPayer(contractAddress, senderAddress);
        (bool creditBalanceCheck, uint256 feeAmount) = _isInsufficientCredit(
            payerAddress,
            "distribution"
        );

        if (creditBalanceCheck) {
            return (
                false,
                "Fee payerAddress insufficient credit",
                payerAddress,
                feeAmount
            );
        }

        if (!_isOriginalContract(contractAddress)) {
            return (
                false,
                "contractAddress is not carina original contract",
                payerAddress,
                feeAmount
            );
        } else {
            if (
                ICRNGeneric(contractAddress).thisContractType() !=
                ContractType.POINT
            ) {
                return (
                    false,
                    "ContractType not support",
                    payerAddress,
                    feeAmount
                );
            }
            if (!_checkSenderPermission(contractAddress, senderAddress)) {
                return (
                    false,
                    "senderAddress has no permission",
                    payerAddress,
                    feeAmount
                );
            }
            if (_isOverDistributeLimit(contractAddress, amount)) {
                return (
                    false,
                    "amount over the distribution limit",
                    payerAddress,
                    feeAmount
                );
            }
        }
        return (true, "", payerAddress, feeAmount);
    }

    function distribution(
        address contractAddress,
        address senderAddress,
        address userAddress,
        uint256 amount,
        address feePayerAddress
    ) external onlyAdmin returns (address, uint256) {
        require(
            _checkSenderPermission(contractAddress, senderAddress),
            "senderAddress has no permission"
        );
        require(
            ICRNGeneric(contractAddress).distribute(userAddress, amount),
            "distibution failed"
        );
        emit Distributed(contractAddress, senderAddress, userAddress, amount);
        return (feePayerAddress, _payFee(feePayerAddress, "distribution"));
    }

    function checkDeduction(
        address contractAddress,
        address senderAddress,
        address userAddress,
        uint256 amount
    ) public view returns (bool, string memory, address, uint256) {
        address payerAddress = _getCreditPayer(contractAddress, senderAddress);
        (bool creditBalanceCheck, uint256 feeAmount) = _isInsufficientCredit(
            payerAddress,
            "deduction"
        );

        if (creditBalanceCheck) {
            return (
                false,
                "Fee payerAddress insufficient credit",
                payerAddress,
                feeAmount
            );
        }

        if (!_isOriginalContract(contractAddress)) {
            return (
                false,
                "contractAddress is not carina original contract",
                payerAddress,
                feeAmount
            );
        } else {
            if (
                ICRNGeneric(contractAddress).thisContractType() !=
                ContractType.POINT
            ) {
                return (
                    false,
                    "ContractType not support",
                    payerAddress,
                    feeAmount
                );
            }
            if (!_checkSenderPermission(contractAddress, senderAddress)) {
                return (
                    false,
                    "senderAddress has no permission",
                    payerAddress,
                    feeAmount
                );
            }
            if (!_hasEnoughBalance(contractAddress, userAddress, amount)) {
                return (
                    false,
                    "userAddress insufficient balance to deduction",
                    payerAddress,
                    feeAmount
                );
            }
        }
        return (true, "", payerAddress, feeAmount);
    }

    function deduction(
        address contractAddress,
        address senderAddress,
        address userAddress,
        uint256 amount,
        address feePayerAddress
    ) external onlyAdmin returns (address, uint256) {
        require(
            _checkSenderPermission(contractAddress, senderAddress),
            "senderAddress has no permission"
        );
        require(
            ICRNGeneric(contractAddress).deduct(userAddress, amount),
            "deduction failed"
        );
        emit Deducted(contractAddress, senderAddress, userAddress, amount);
        return (feePayerAddress, _payFee(feePayerAddress, "deduction"));
    }

    function checkUserTransfer(
        address contractAddress,
        address fromAddress,
        address toAddress,
        uint256 amount
    ) public view returns (bool, string memory, address, uint256) {
        (bool creditBalanceCheck, uint256 feeAmount) = _isInsufficientCredit(
            fromAddress,
            "userTransfer"
        );
        if (creditBalanceCheck) {
            return (
                false,
                "fromAddress insufficient credit",
                fromAddress,
                feeAmount
            );
        }

        if (!_isOriginalContract(contractAddress)) {
            return (
                false,
                "contractAddress is not carina original contract",
                fromAddress,
                feeAmount
            );
        } else {
            if (
                ICRNGeneric(contractAddress).thisContractType() !=
                ContractType.POINT
            ) {
                return (
                    false,
                    "ContractType not support",
                    fromAddress,
                    feeAmount
                );
            }
            if (!_isRegisteredUser(fromAddress)) {
                return (
                    false,
                    "fromAddress is not registered",
                    fromAddress,
                    feeAmount
                );
            }
            if (!_hasEnoughBalance(contractAddress, fromAddress, amount)) {
                return (
                    false,
                    "fromAddress Insufficient balance",
                    fromAddress,
                    feeAmount
                );
            }
            if (!_isRegisteredUser(toAddress)) {
                return (
                    false,
                    "toAddress is not registered",
                    fromAddress,
                    feeAmount
                );
            }
        }
        return (true, "", fromAddress, feeAmount);
    }

    function userTransfer(
        address contractAddress,
        address fromAddress,
        address toAddress,
        uint256 amount
    ) external onlyAdmin returns (address, uint256) {
        require(
            _isRegisteredUser(fromAddress) && _isRegisteredUser(toAddress),
            "from and to user must be registered"
        );
        require(
            ICRNGeneric(contractAddress).pTransfer(
                fromAddress,
                toAddress,
                amount
            ),
            "userTransfer failed"
        );
        emit userTransferred(contractAddress, fromAddress, toAddress, amount);
        return (fromAddress, _payFee(fromAddress, "userTransfer"));
    }

    function checkIssueMembership(
        address contractAddress,
        address senderAddress,
        address memberAddress,
        uint256 level
    ) public view returns (bool, string memory, address, uint256) {
        address payerAddress = _getCreditPayer(contractAddress, senderAddress);
        (bool creditBalanceCheck, uint256 feeAmount) = _isInsufficientCredit(
            payerAddress,
            "issueMembership"
        );

        if (creditBalanceCheck) {
            return (
                false,
                "Fee payerAddress insufficient credit",
                payerAddress,
                feeAmount
            );
        }

        if (!_isOriginalContract(contractAddress)) {
            return (
                false,
                "contractAddress is not carina original contract",
                payerAddress,
                feeAmount
            );
        } else {
            if (level == 0) {
                return (
                    false,
                    "level can not be zero",
                    payerAddress,
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
                    payerAddress,
                    feeAmount
                );
            }
            if (!_checkSenderPermission(contractAddress, senderAddress)) {
                return (
                    false,
                    "senderAddress has no permission",
                    payerAddress,
                    feeAmount
                );
            }
            if (ICRNGeneric(contractAddress).hasMembership(memberAddress)) {
                return (
                    false,
                    "Membership already issued",
                    payerAddress,
                    feeAmount
                );
            }
        }
        return (true, "", payerAddress, feeAmount);
    }

    function issueMembership(
        address contractAddress,
        address senderAddress,
        address memberAddress,
        uint256 level,
        address feePayerAddress
    ) external onlyAdmin returns (address, uint256) {
        require(
            _checkSenderPermission(contractAddress, senderAddress),
            "senderAddress has no permission"
        );
        require(
            ICRNGeneric(contractAddress).issueMembership(
                senderAddress,
                memberAddress,
                level
            ),
            "issueMembership failed"
        );
        emit MembershipIssued(contractAddress, senderAddress, memberAddress);
        return (feePayerAddress, _payFee(feePayerAddress, "issueMembership"));
    }

    function checkRevokeMembership(
        address contractAddress,
        address senderAddress,
        address memberAddress
    ) public view returns (bool, string memory, address, uint256) {
        address payerAddress = _getCreditPayer(contractAddress, senderAddress);
        (bool creditBalanceCheck, uint256 feeAmount) = _isInsufficientCredit(
            payerAddress,
            "revokeMembership"
        );

        if (creditBalanceCheck) {
            return (
                false,
                "Fee payerAddress insufficient credit",
                payerAddress,
                feeAmount
            );
        }

        if (!_isOriginalContract(contractAddress)) {
            return (
                false,
                "contractAddress is not carina original contract",
                payerAddress,
                feeAmount
            );
        } else {
            if (
                ICRNGeneric(contractAddress).thisContractType() !=
                ContractType.MEMBERSHIP
            ) {
                return (
                    false,
                    "ContractType not support",
                    payerAddress,
                    feeAmount
                );
            }
            if (!_checkSenderPermission(contractAddress, senderAddress)) {
                return (
                    false,
                    "senderAddress has no permission",
                    payerAddress,
                    feeAmount
                );
            }
            if (!ICRNGeneric(contractAddress).hasMembership(memberAddress)) {
                return (false, "no membership issued", payerAddress, feeAmount);
            }
        }
        return (true, "", payerAddress, feeAmount);
    }

    function revokeMembership(
        address contractAddress,
        address senderAddress,
        address memberAddress,
        address feePayerAddress
    ) external onlyAdmin returns (address, uint256) {
        require(
            _checkSenderPermission(contractAddress, senderAddress),
            "senderAddress has no permission"
        );
        require(
            ICRNGeneric(contractAddress).revokeMembership(
                senderAddress,
                memberAddress
            ),
            "revokeMembership failed"
        );
        emit MembershipRevoked(contractAddress, senderAddress, memberAddress);
        return (feePayerAddress, _payFee(feePayerAddress, "revokeMembership"));
    }

    function checkChangeMemberLevel(
        address contractAddress,
        address senderAddress,
        address memberAddress,
        uint256 newValue
    ) public view returns (bool, string memory, address, uint256) {
        address payerAddress = _getCreditPayer(contractAddress, senderAddress);
        (bool creditBalanceCheck, uint256 feeAmount) = _isInsufficientCredit(
            payerAddress,
            "changeMemberLevel"
        );

        if (creditBalanceCheck) {
            return (
                false,
                "Fee payerAddress insufficient credit",
                payerAddress,
                feeAmount
            );
        }

        if (!_isOriginalContract(contractAddress)) {
            return (
                false,
                "contractAddress is not carina original contract",
                payerAddress,
                feeAmount
            );
        } else {
            if (newValue == 0) {
                return (
                    false,
                    "newValue can not be zero",
                    payerAddress,
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
                    payerAddress,
                    feeAmount
                );
            }
            if (!_checkSenderPermission(contractAddress, senderAddress)) {
                return (
                    false,
                    "senderAddress has no permission",
                    payerAddress,
                    feeAmount
                );
            }
            if (!ICRNGeneric(contractAddress).hasMembership(memberAddress)) {
                return (false, "no membership issued", payerAddress, feeAmount);
            }
        }
        return (true, "", payerAddress, feeAmount);
    }

    function changeMemberLevel(
        address contractAddress,
        address senderAddress,
        address memberAddress,
        uint256 level,
        address feePayerAddress
    ) external onlyAdmin returns (address, uint256) {
        require(
            _checkSenderPermission(contractAddress, senderAddress),
            "senderAddress has no permission"
        );
        require(
            ICRNGeneric(contractAddress).changeMemberLevel(
                senderAddress,
                memberAddress,
                level
            ),
            "changeMemberLevel failed"
        );
        emit MemberLevelChanged(contractAddress, senderAddress, memberAddress);
        return (feePayerAddress, _payFee(feePayerAddress, "changeMemberLevel"));
    }

    function updateAdmin() external {
        _updateAdmin(thisContractType);
    }
}
