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

import "./RoleController.sol";

/**
 * @title AuthorityIssuerData
 * Authority Issuer data contract.
 */

contract AuthorityIssuerData {

    // Error codes
    uint private RETURN_CODE_SUCCESS = 0;
    uint private RETURN_CODE_FAILURE_ALREADY_EXISTS = 500201;
    uint private RETURN_CODE_FAILURE_NOT_EXIST = 500202;
    uint private RETURN_CODE_NAME_ALREADY_EXISTS = 500203;
    uint private RETURN_CODE_UNRECOGNIZED = 500204;

    struct AuthorityIssuer {
        // [0]: name, [1]: desc, [2-11]: extra string
        bytes32[16] attribBytes32;
        // [0]: create date, [1]: update date, [2-11]: extra int
        // [15]: flag for recognition status (0: unrecognized, 1: recognized)
        int[16] attribInt;
        bytes accValue;
    }

    mapping (address => AuthorityIssuer) private authorityIssuerMap;
    address[] private authorityIssuerArray;
    mapping (bytes32 => address) private uniqueNameMap;
    uint recognizedIssuerCount = 0;

    RoleController private roleController;

    // Constructor
    constructor(address addr) public {
        roleController = RoleController(addr);
    }

    function isAuthorityIssuer(
        address addr
    ) 
        public 
        view 
        returns (bool) 
    {
        if (!roleController.checkRole(addr, roleController.ROLE_AUTHORITY_ISSUER())) {
            return false;
        }
        if (authorityIssuerMap[addr].attribBytes32[0] == bytes32(0)) {
            return false;
        }
        return true;
    }

    function addAuthorityIssuerFromAddress(
        address addr,
        bytes32[16] memory attribBytes32,
        int[16] memory attribInt,
        bytes memory accValue
    )
        public
        returns (uint)
    {
        if (authorityIssuerMap[addr].attribBytes32[0] != bytes32(0)) {
            return RETURN_CODE_FAILURE_ALREADY_EXISTS;
        }
        if (isNameDuplicate(attribBytes32[0])) {
            return RETURN_CODE_NAME_ALREADY_EXISTS;
        }

        // Actual Role must be granted by calling recognizeAuthorityIssuer()
        // roleController.addRole(addr, roleController.ROLE_AUTHORITY_ISSUER());

        AuthorityIssuer memory authorityIssuer = AuthorityIssuer(attribBytes32, attribInt, accValue);
        authorityIssuerMap[addr] = authorityIssuer;
        authorityIssuerArray.push(addr);
        uniqueNameMap[attribBytes32[0]] = addr;
        return RETURN_CODE_SUCCESS;
    }
    
    function recognizeAuthorityIssuer(address addr) public returns (uint) {
        if (!roleController.checkPermission(tx.origin, roleController.MODIFY_AUTHORITY_ISSUER())) {
            return roleController.RETURN_CODE_FAILURE_NO_PERMISSION();
        }
        if (authorityIssuerMap[addr].attribBytes32[0] == bytes32(0)) {
            return RETURN_CODE_FAILURE_NOT_EXIST;
        }
        // Set role and flag
        roleController.addRole(addr, roleController.ROLE_AUTHORITY_ISSUER());
        recognizedIssuerCount = recognizedIssuerCount + 1;
        authorityIssuerMap[addr].attribInt[15] = int(1);
        return RETURN_CODE_SUCCESS;
    }

    function deRecognizeAuthorityIssuer(address addr) public returns (uint) {
        if (!roleController.checkPermission(tx.origin, roleController.MODIFY_AUTHORITY_ISSUER())) {
            return roleController.RETURN_CODE_FAILURE_NO_PERMISSION();
        }
        // Remove role and flag
        roleController.removeRole(addr, roleController.ROLE_AUTHORITY_ISSUER());
        recognizedIssuerCount = recognizedIssuerCount - 1;
        authorityIssuerMap[addr].attribInt[15] = int(0);
        return RETURN_CODE_SUCCESS;
    }

    function deleteAuthorityIssuerFromAddress(
        address addr
    ) 
        public 
        returns (uint)
    {
        if (authorityIssuerMap[addr].attribBytes32[0] == bytes32(0)) {
            return RETURN_CODE_FAILURE_NOT_EXIST;
        }
        if (!roleController.checkPermission(tx.origin, roleController.MODIFY_AUTHORITY_ISSUER())) {
            return roleController.RETURN_CODE_FAILURE_NO_PERMISSION();
        }
        roleController.removeRole(addr, roleController.ROLE_AUTHORITY_ISSUER());
        if (authorityIssuerMap[addr].attribInt[15] == int(1)) {
            recognizedIssuerCount = recognizedIssuerCount - 1;
        }
        uniqueNameMap[authorityIssuerMap[addr].attribBytes32[0]] = address(0x0);
        delete authorityIssuerMap[addr];
        uint datasetLength = authorityIssuerArray.length;
        for (uint index = 0; index < datasetLength; index++) {
            if (authorityIssuerArray[index] == addr) { 
                if (index != datasetLength-1) {
                    authorityIssuerArray[index] = authorityIssuerArray[datasetLength-1];
                }
                break; 
            }
        } 
        authorityIssuerArray.pop();
        return RETURN_CODE_SUCCESS;
    }

    function getDatasetLength() 
        public 
        view 
        returns (uint) 
    {
        return authorityIssuerArray.length;
    }

    function getAuthorityIssuerFromIndex(
        uint index
    ) 
        public 
        view 
        returns (address) 
    {
        return authorityIssuerArray[index];
    }

    function getAuthorityIssuerInfoNonAccValue(
        address addr
    )
        public
        view
        returns (bytes32[16] memory, int[16] memory)
    {
        bytes32[16] memory allBytes32;
        int[16] memory allInt;
        for (uint index = 0; index < 16; index++) {
            allBytes32[index] = authorityIssuerMap[addr].attribBytes32[index];
            allInt[index] = authorityIssuerMap[addr].attribInt[index];
        }
        return (allBytes32, allInt);
    }

    function getAuthorityIssuerInfoAccValue(
        address addr
    ) 
        public 
        view 
        returns (bytes memory) 
    {
        return authorityIssuerMap[addr].accValue;
    }

    function isNameDuplicate(
        bytes32 name
    )
        public
        view
        returns (bool) 
    {
        if (uniqueNameMap[name] == address(0x0)) {
            return false;
        }
        return true;
    }

    function getAddressFromName(
        bytes32 name
    )
        public
        view
        returns (address)
    {
        return uniqueNameMap[name];
    }
    
    function getRecognizedIssuerCount() 
        public 
        view 
        returns (uint) 
    {
        return recognizedIssuerCount;
    }
}