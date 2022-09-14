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

/**
 * @title RoleController
 *  This contract provides basic authentication control which defines who (address)
 *  belongs to what specific role and has what specific permission.
 */

contract RoleController {

    /**
     * The universal NO_PERMISSION error code.
     */
    uint public RETURN_CODE_FAILURE_NO_PERMISSION = 500000;

    /**
     * Role related Constants.
     */
    uint public ROLE_AUTHORITY_ISSUER = 100;
    uint public ROLE_COMMITTEE = 101;
    uint public ROLE_ADMIN = 102;

    /**
     * Operation related Constants.
     */
    uint public MODIFY_AUTHORITY_ISSUER = 200;
    uint public MODIFY_COMMITTEE = 201;
    uint public MODIFY_ADMIN = 202;
    uint public MODIFY_KEY_CPT = 203;

    mapping (address => bool) private authorityIssuerRoleBearer;
    mapping (address => bool) private committeeMemberRoleBearer;
    mapping (address => bool) private adminRoleBearer;

    constructor() public {
        authorityIssuerRoleBearer[msg.sender] = true;
        adminRoleBearer[msg.sender] = true;
        committeeMemberRoleBearer[msg.sender] = true;
    }

    /**
     * Public common checkPermission logic.
     */
    function checkPermission(
        address addr,
        uint operation
    ) 
        public 
        view 
        returns (bool) 
    {
        if (operation == MODIFY_AUTHORITY_ISSUER) {
            if (adminRoleBearer[addr] || committeeMemberRoleBearer[addr]) {
                return true;
            }
        }
        if (operation == MODIFY_COMMITTEE) {
            if (adminRoleBearer[addr]) {
                return true;
            }
        }
        if (operation == MODIFY_ADMIN) {
            if (adminRoleBearer[addr]) {
                return true;
            }
        }
        if (operation == MODIFY_KEY_CPT) {
            if (authorityIssuerRoleBearer[addr]) {
                return true;
            }
        }
        return false;
    }

    /**
     * Add Role.
     */
    function addRole(
        address addr,
        uint role
    ) 
        public 
    {
        if (role == ROLE_AUTHORITY_ISSUER) {
            if (checkPermission(tx.origin, MODIFY_AUTHORITY_ISSUER)) {
                authorityIssuerRoleBearer[addr] = true;
            }
        }
        if (role == ROLE_COMMITTEE) {
            if (checkPermission(tx.origin, MODIFY_COMMITTEE)) {
                committeeMemberRoleBearer[addr] = true;
            }
        }
        if (role == ROLE_ADMIN) {
            if (checkPermission(tx.origin, MODIFY_ADMIN)) {
                adminRoleBearer[addr] = true;
            }
        }
    }

    /**
     * Remove Role.
     */
    function removeRole(
        address addr,
        uint role
    ) 
        public 
    {
        if (role == ROLE_AUTHORITY_ISSUER) {
            if (checkPermission(tx.origin, MODIFY_AUTHORITY_ISSUER)) {
                authorityIssuerRoleBearer[addr] = false;
            }
        }
        if (role == ROLE_COMMITTEE) {
            if (checkPermission(tx.origin, MODIFY_COMMITTEE)) {
                committeeMemberRoleBearer[addr] = false;
            }
        }
        if (role == ROLE_ADMIN) {
            if (checkPermission(tx.origin, MODIFY_ADMIN)) {
                adminRoleBearer[addr] = false;
            }
        }
    }

    /**
     * Check Role.
     */
    function checkRole(
        address addr,
        uint role
    ) 
        public 
        view 
        returns (bool) 
    {
        if (role == ROLE_AUTHORITY_ISSUER) {
            return authorityIssuerRoleBearer[addr];
        }
        if (role == ROLE_COMMITTEE) {
            return committeeMemberRoleBearer[addr];
        }
        if (role == ROLE_ADMIN) {
            return adminRoleBearer[addr];
        }
    }
}
