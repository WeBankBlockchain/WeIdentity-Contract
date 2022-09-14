pragma solidity >=0.6.10 <0.8.20;
pragma experimental ABIEncoderV2;

/*
 *       Copyright© (2018) WeBank Co., Ltd.
 *
 *       Licensed under the Apache License, Version 2.0 (the "License");
 *       you may not use this file except in compliance with the License.
 *       You may obtain a copy of the License at

 *          http://www.apache.org/licenses/LICENSE-2.0
 *
 *       Unless required by applicable law or agreed to in writing, software
 *       distributed under the License is distributed on an "AS IS" BASIS,
 *       WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *       See the License for the specific language governing permissions and
 *       limitations under the License.
 *      
 */
//SPDX-License-Identifier: Apache-2.0

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
    uint private OPERATION_ADD = 0;
    uint private OPERATION_REMOVE = 1;
    uint private EMPTY_ARRAY_SIZE = 1;

    event AuthorityIssuerRetLog(uint operation, uint retCode, address addr);

    // Constructor.
    constructor(
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
        bytes32[16] memory attribBytes32,
        int[16] memory attribInt,
        bytes memory accValue
    )
        public
    {
        uint result = authorityIssuerData.addAuthorityIssuerFromAddress(addr, attribBytes32, attribInt, accValue);
        emit AuthorityIssuerRetLog(OPERATION_ADD, result, addr);
    }
    
    function recognizeAuthorityIssuer(address addr) public {
        uint result = authorityIssuerData.recognizeAuthorityIssuer(addr);
        emit AuthorityIssuerRetLog(OPERATION_ADD, result, addr);
    }

    function deRecognizeAuthorityIssuer(address addr) public {
        uint result = authorityIssuerData.deRecognizeAuthorityIssuer(addr);
        emit AuthorityIssuerRetLog(OPERATION_REMOVE, result, addr);
    }

    function removeAuthorityIssuer(address addr) public {
        if (!roleController.checkPermission(tx.origin, roleController.MODIFY_AUTHORITY_ISSUER())) {
            emit AuthorityIssuerRetLog(OPERATION_REMOVE, roleController.RETURN_CODE_FAILURE_NO_PERMISSION(), addr);
            return;
        }
        uint result = authorityIssuerData.deleteAuthorityIssuerFromAddress(addr);
        emit AuthorityIssuerRetLog(OPERATION_REMOVE, result, addr);
    }

    function getTotalIssuer() public view returns (uint) {
        return authorityIssuerData.getDatasetLength();
    }

    function getAuthorityIssuerAddressList(
        uint startPos,
        uint num
    ) 
        public 
        view 
        returns (address[] memory) 
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
        view
        returns (bytes32[] memory, int[] memory)
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
        view 
        returns (bool) 
    {
        return authorityIssuerData.isAuthorityIssuer(addr);
    }

    function getAddressFromName(
        bytes32 name
    )
        public
        view
        returns (address)
    {
        return authorityIssuerData.getAddressFromName(name);
    }
    
    function getRecognizedIssuerCount() 
        public 
        view 
        returns (uint) 
    {
        return authorityIssuerData.getRecognizedIssuerCount();
    }
}