// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

enum UserType {
    UNREGISTERED,
    DELETED,
    TENANT,
    STORE,
    CLERK,
    GENERAL,
    BUSINESSPARTNER,
    THIRDPARTY,
    SERVICEPROVIDER,
    ADMINISTRATOR,
    OTHERS
}

enum RelationType {
    UNDEFINED,
    CLEARED,
    FEEFREE,
    FEESELFPAY
}

enum ContractType {
    UNDEFINED,
    POINT,
    COUPON,
    STAMP,
    SWAPPOOL,
    MISSION,
    THIRDPARTY,
    USER,
    POINTFACTORY,
    COUPONFACTORY,
    STAMPFACTORY,
    SWAPPOOLFACTORY,
    MISSIONFACTORY,
    THIRDPARTYFACTORY,
    ADMINCONTROLER,
    USERMANAGER,
    ROUTER,
    CRNCONVERTER,
    CREDITPOINT,
    POINTCRN,
    CRNTOKEN,
    OTHER_ONE,
    OTHER_TWO,
    OTHER_THREE
}

struct TokenValue {
    uint256 valueAmount;
    string valueCurrency;
}
