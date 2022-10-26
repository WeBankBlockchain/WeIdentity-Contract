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

import "./CommitteeMemberData.sol";
import "./RoleController.sol";

/**
 * @title CommitteeMemberController
 * Issuer contract manages authority issuer info.
 */

contract CommitteeMemberController {

    CommitteeMemberData private committeeMemberData;
    RoleController private roleController;

    // Event structure to store tx records
    uint private OPERATION_ADD = 0;
    uint private OPERATION_REMOVE = 1;
    
    event CommitteeRetLog(uint operation, uint retCode, address addr);

    // Constructor.
    constructor(
        address committeeMemberDataAddress,
        address roleControllerAddress
    )
        public 
    {
        committeeMemberData = CommitteeMemberData(committeeMemberDataAddress);
        roleController = RoleController(roleControllerAddress);
    }
    
    function addCommitteeMember(
        address addr
    ) 
        public 
    {
        if (!roleController.checkPermission(tx.origin, roleController.MODIFY_COMMITTEE())) {
            emit CommitteeRetLog(OPERATION_ADD, roleController.RETURN_CODE_FAILURE_NO_PERMISSION(), addr);
            return;
        }
        uint result = committeeMemberData.addCommitteeMemberFromAddress(addr);
        emit CommitteeRetLog(OPERATION_ADD, result, addr);
    }

    function removeCommitteeMember(
        address addr
    ) 
        public 
    {
        if (!roleController.checkPermission(tx.origin, roleController.MODIFY_COMMITTEE())) {
            emit CommitteeRetLog(OPERATION_REMOVE, roleController.RETURN_CODE_FAILURE_NO_PERMISSION(), addr);
            return;
        }
        uint result = committeeMemberData.deleteCommitteeMemberFromAddress(addr);
        emit CommitteeRetLog(OPERATION_REMOVE, result, addr);
    }

    function getAllCommitteeMemberAddress() 
        public 
        view 
        returns (address[] memory) 
    {
        // Per-index access
        uint datasetLength = committeeMemberData.getDatasetLength();
        address[] memory memberArray = new address[](datasetLength);
        for (uint index = 0; index < datasetLength; index++) {
            memberArray[index] = committeeMemberData.getCommitteeMemberAddressFromIndex(index);
        }
        return memberArray;
    }

    function isCommitteeMember(
        address addr
    ) 
        public 
        view 
        returns (bool) 
    {
        return committeeMemberData.isCommitteeMember(addr);
    }
}