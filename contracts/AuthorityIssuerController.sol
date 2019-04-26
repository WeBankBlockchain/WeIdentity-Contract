pragma solidity ^0.4.4;
/*
 *       Copyright© (2018-2019) WeBank Co., Ltd.
 *
 *       This file is part of weidentity-contract.
 *
 *       weidentity-contract is free software: you can redistribute it and/or modify
 *       it under the terms of the GNU Lesser General Public License as published by
 *       the Free Software Foundation, either version 3 of the License, or
 *       (at your option) any later version.
 *
 *       weidentity-contract is distributed in the hope that it will be useful,
 *       but WITHOUT ANY WARRANTY; without even the implied warranty of
 *       MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *       GNU Lesser General Public License for more details.
 *
 *       You should have received a copy of the GNU Lesser General Public License
 *       along with weidentity-contract.  If not, see <https://www.gnu.org/licenses/>.
 */

import "./AuthorityIssuerData.sol";
import "./RoleController.sol";

/**
 * @title AuthorityIssuerController
 * Issuer contract manages authority issuer info.
 */

contract AuthorityIssuerController {

    AuthorityIssuerData private authorityIssuerData;
    RoleController private roleController;

    // Event structure to store tx records
    uint constant private OPERATION_ADD = 0;
    uint constant private OPERATION_REMOVE = 1;
    uint constant private RETURN_CODE_SUCCESS = 0;
    uint constant private RETURN_CODE_FAILURE_ALREADY_EXISTS = 500201;
    uint constant private RETURN_CODE_FAILURE_NOT_EXIST = 500202;
    uint constant private RETURN_CODE_FAILURE_NO_PERMISSION = 500203;
    uint constant private RETURN_CODE_NAME_ALREADY_EXISTS = 500204;
    uint constant private EMPTY_ARRAY_SIZE = 1;

    event AuthorityIssuerRetLog(uint operation, uint retCode, address addr);

    // Constructor.
    function AuthorityIssuerController(
        address authorityIssuerDataAddress,
        address roleControllerAddress
    ) 
        public 
    {
        authorityIssuerData = AuthorityIssuerData(authorityIssuerDataAddress);
        roleController = RoleController(roleControllerAddress);
    }

    function addAuthorityIssuer(
        address addr,
        bytes32[16] attribBytes32,
        int[16] attribInt,
        bytes accValue
    )
        public
    {
        if (authorityIssuerData.isNameDuplicate(attribBytes32[0])) {
            AuthorityIssuerRetLog(OPERATION_ADD, RETURN_CODE_NAME_ALREADY_EXISTS, addr);
            return;
        }
        if (authorityIssuerData.isAuthorityIssuer(addr)) {
            AuthorityIssuerRetLog(OPERATION_ADD, RETURN_CODE_FAILURE_ALREADY_EXISTS, addr);
            return;
        } else if (!roleController.checkPermission(tx.origin, roleController.MODIFY_AUTHORITY_ISSUER())) {
            AuthorityIssuerRetLog(OPERATION_ADD, RETURN_CODE_FAILURE_NO_PERMISSION, addr);
            return;
        } else {
            authorityIssuerData.addAuthorityIssuerFromAddress(addr, attribBytes32, attribInt, accValue);
            AuthorityIssuerRetLog(OPERATION_ADD, RETURN_CODE_SUCCESS, addr);
        }
    }

    function removeAuthorityIssuer(
        address addr
    ) 
        public 
    {
        if (!authorityIssuerData.isAuthorityIssuer(addr)) {
            AuthorityIssuerRetLog(OPERATION_REMOVE, RETURN_CODE_FAILURE_NOT_EXIST, addr);
            return;
        } else if (!roleController.checkPermission(tx.origin, roleController.MODIFY_AUTHORITY_ISSUER())) {
            AuthorityIssuerRetLog(OPERATION_REMOVE, RETURN_CODE_FAILURE_NO_PERMISSION, addr);
            return;
        } else {
            authorityIssuerData.deleteAuthorityIssuerFromAddress(addr);
            AuthorityIssuerRetLog(OPERATION_REMOVE, RETURN_CODE_SUCCESS, addr);
        }
    }

    function getAllAuthorityIssuerAddress(
        uint startPos,
        uint num
    ) 
        public 
        constant 
        returns (address[]) 
    {
        uint totalLength = authorityIssuerData.getDatasetLength();

        uint dataLength;
        // Calculate actual dataLength
        if (totalLength < startPos) {
            return new address[](EMPTY_ARRAY_SIZE);
        } else if (totalLength <= startPos + num) {
            dataLength = totalLength - startPos;
        } else {
            dataLength = num;
        }

        address[] memory issuerArray = new address[](dataLength);
        for (uint index = 0; index < dataLength; index++) {
            issuerArray[index] = authorityIssuerData.getAuthorityIssuerFromIndex(startPos + index);
        }
        return issuerArray;
    }

    function getAuthorityIssuerInfoNonAccValue(
        address addr
    )
        public
        constant
        returns (bytes32[], int[])
    {
        // Due to the current limitations of bcos web3j, return dynamic bytes32 and int array instead.
        bytes32[16] memory allBytes32;
        int[16] memory allInt;
        (allBytes32, allInt) = authorityIssuerData.getAuthorityIssuerInfoNonAccValue(addr);
        bytes32[] memory finalBytes32 = new bytes32[](16);
        int[] memory finalInt = new int[](16);
        for (uint index = 0; index < 16; index++) {
            finalBytes32[index] = allBytes32[index];
            finalInt[index] = allInt[index];
        }
        return (finalBytes32, finalInt);
    }

    function isAuthorityIssuer(
        address addr
    ) 
        public 
        constant 
        returns (bool) 
    {
        return authorityIssuerData.isAuthorityIssuer(addr);
    }
}