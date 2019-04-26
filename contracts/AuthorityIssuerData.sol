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

import "./RoleController.sol";

/**
 * @title AuthorityIssuerData
 * Authority Issuer data contract.
 */

contract AuthorityIssuerData {

    struct AuthorityIssuer {
        // [0]: name
        bytes32[16] attribBytes32;
        // [0]: create date
        int[16] attribInt;
        bytes accValue;
    }

    // Mapping key: address (WeID address), value: Authority Issuer instance.
    mapping (address => AuthorityIssuer) private authorityIssuerMap;
    // Array used to index and count the address (WeID address). Depends on mapping, no standalone creator.
    address[] private authorityIssuerArray;
    // Unique authority issuer name mapping.
    mapping (bytes32 => bool) private uniqueNameMap;

    RoleController private roleController;

    // Constructor.
    function AuthorityIssuerData(address addr) public {
        roleController = RoleController(addr);
    }

    function isAuthorityIssuer(
        address addr
    ) 
        public 
        constant 
        returns (bool) 
    {
        // Use LOCAL ARRAY INDEX here, not the RoleController data.
        // The latter one might lose track in the fresh-deploy or upgrade case.
        for (uint index = 0; index < authorityIssuerArray.length; index++) {
            if (authorityIssuerArray[index] == addr) {
                return true;
            }
        }
        return false;
    }

    function addAuthorityIssuerFromAddress(
        address addr,
        bytes32[16] attribBytes32,
        int[16] attribInt,
        bytes accValue
    )
        public
    {
        if (isAuthorityIssuer(addr) || isNameDuplicate(attribBytes32[0])) {
            return;
        }

        if (!roleController.checkPermission(tx.origin, roleController.MODIFY_AUTHORITY_ISSUER())) {
            return;
        }

        roleController.addRole(addr, roleController.ROLE_AUTHORITY_ISSUER());
        AuthorityIssuer memory authorityIssuer = AuthorityIssuer(attribBytes32, attribInt, accValue);
        authorityIssuerMap[addr] = authorityIssuer;
        authorityIssuerArray.push(addr);
        uniqueNameMap[attribBytes32[0]] = true;
    }

    function deleteAuthorityIssuerFromAddress(
        address addr
    ) 
        public 
    {
        if (!isAuthorityIssuer(addr)) {
            return;
        }

        if (!roleController.checkPermission(tx.origin, roleController.MODIFY_AUTHORITY_ISSUER())) {
            return;
        }

        roleController.removeRole(addr, roleController.ROLE_AUTHORITY_ISSUER());
        uniqueNameMap[authorityIssuerMap[addr].attribBytes32[0]] = false;
        delete authorityIssuerMap[addr];
        uint datasetLength = authorityIssuerArray.length;
        for (uint index = 0; index < datasetLength; index++) {
            if (authorityIssuerArray[index] == addr) { 
                break; 
            }
        } 
        if (index != datasetLength-1) {
            authorityIssuerArray[index] = authorityIssuerArray[datasetLength-1];
        }
        delete authorityIssuerArray[datasetLength-1];
        authorityIssuerArray.length--;
    }

    function getDatasetLength() 
        public 
        constant 
        returns (uint) 
    {
        return authorityIssuerArray.length;
    }

    function getAuthorityIssuerFromIndex(
        uint index
    ) 
        public 
        constant 
        returns (address) 
    {
        return authorityIssuerArray[index];
    }

    function getAuthorityIssuerInfoNonAccValue(
        address addr
    )
        public
        constant
        returns (bytes32[16], int[16])
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
        constant 
        returns (bytes) 
    {
        return authorityIssuerMap[addr].accValue;
    }

    function isNameDuplicate(
        bytes32 name
    )
        public
        constant
        returns (bool) 
    {
        return uniqueNameMap[name];
    }
}