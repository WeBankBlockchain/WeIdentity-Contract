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
 * @title CommitteeMemberData
 * CommitteeMember data contract.
 */

contract CommitteeMemberData {

    uint private RETURN_CODE_SUCCESS = 0;
    uint private RETURN_CODE_FAILURE_ALREADY_EXISTS = 500251;
    uint private RETURN_CODE_FAILURE_NOT_EXIST = 500252;

    address[] private committeeMemberArray;
    RoleController private roleController;

    constructor(address addr) public {
        roleController = RoleController(addr);
    }

    function isCommitteeMember(
        address addr
    ) 
        public 
        view 
        returns (bool) 
    {
        // Use LOCAL ARRAY INDEX here, not the RoleController data.
        // The latter one might lose track in the fresh-deploy or upgrade case.
        for (uint index = 0; index < committeeMemberArray.length; index++) {
            if (committeeMemberArray[index] == addr) {
                return true;
            }
        }
        return false;
    }

    function addCommitteeMemberFromAddress(
        address addr
    ) 
        public
        returns (uint)
    {
        if (isCommitteeMember(addr)) {
            return RETURN_CODE_FAILURE_ALREADY_EXISTS;
        }
        if (!roleController.checkPermission(tx.origin, roleController.MODIFY_COMMITTEE())) {
            return roleController.RETURN_CODE_FAILURE_NO_PERMISSION();
        }
        roleController.addRole(addr, roleController.ROLE_COMMITTEE());
        committeeMemberArray.push(addr);
        return RETURN_CODE_SUCCESS;
    }

    function deleteCommitteeMemberFromAddress(
        address addr
    ) 
        public
        returns (uint)
    {
        if (!isCommitteeMember(addr)) {
            return RETURN_CODE_FAILURE_NOT_EXIST;
        }
        if (!roleController.checkPermission(tx.origin, roleController.MODIFY_COMMITTEE())) {
            return roleController.RETURN_CODE_FAILURE_NO_PERMISSION();
        }
        roleController.removeRole(addr, roleController.ROLE_COMMITTEE());
        uint datasetLength = committeeMemberArray.length;
        for (uint index = 0; index < datasetLength; index++) {
            if (committeeMemberArray[index] == addr) {
                if (index != datasetLength-1) {
                    committeeMemberArray[index] = committeeMemberArray[datasetLength-1];
                }
                break;
            }
        }
        committeeMemberArray.pop();
        return RETURN_CODE_SUCCESS;
    }

    function getDatasetLength() 
        public 
        view 
        returns (uint) 
    {
        return committeeMemberArray.length;
    }

    function getCommitteeMemberAddressFromIndex(
        uint index
    ) 
        public 
        view 
        returns (address) 
    {
        return committeeMemberArray[index];
    }
}