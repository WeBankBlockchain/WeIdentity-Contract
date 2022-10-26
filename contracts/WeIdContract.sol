pragma solidity  >=0.6.10 <0.8.20;
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
contract WeIdContract {

    //WeID Document MetaData struct
    struct MetaData {
        string created;
        string updated;
        bool deactivated;
        uint16 versionId;
    }
    //WeID Document struct
    struct Document {
        MetaData metaData;
        string[] authentication;
        string[] service;
    }
    //method-specific-id(WeId address) => WeID Document
    mapping(address => Document) public weidDocuments;
    
    //Array with all method-specific-id(WeId address), used for enumeration
    address[] public weids;

    event CreateWeId(
        address indexed owner,
        string created,
        uint256 index
    );

    event UpdateWeId(
        address indexed owner,
        string updated,
        uint16 versionId
    );
    
    event DeactivateWeId(
        address indexed owner,
        bool deactivated
    );

    function getWeIdCount() 
        public 
        view 
        returns (uint256) 
    {
        return weids.length;
    }

    function createWeId(
        address identity,
        string memory created,
        string[] memory authentication,
        string[] memory service
    )
        public
    {
        require(!isIdentityExist(identity), "weid existed!");
        MetaData memory _metaData = MetaData(created, created, false, 1);
        weidDocuments[identity].metaData = _metaData;
        weidDocuments[identity].authentication = authentication;
        weidDocuments[identity].service = service;
        emit CreateWeId(identity, created, weids.length);
        weids.push(identity);
    }
    
    function updateWeId(
        address identity,
        string memory updated,
        string[] memory authentication,
        string[] memory service
    )
        public
    {
        require(isIdentityExist(identity), "weid not existed!");
        require(msg.sender == identity, "only the controller can update document!");
        MetaData storage _metaData = weidDocuments[identity].metaData;
        require(!_metaData.deactivated, "this weid has been deactivated!");
        _metaData.updated = updated;
        _metaData.versionId++;
        weidDocuments[identity].authentication = authentication;
        weidDocuments[identity].service = service;
        emit UpdateWeId(identity, updated, _metaData.versionId);
    }
    
    function deactivateWeId(
        address identity,
        bool deactivated
    )
        public
    {
        require(isIdentityExist(identity), "weid not existed!");
        require(msg.sender == identity, "only the controller can deactivate!");
        MetaData storage _metaData = weidDocuments[identity].metaData;
        require(_metaData.deactivated != deactivated, "this weid has been deactivated or activated!");
        _metaData.deactivated = deactivated;
        emit DeactivateWeId(identity, deactivated);
    }

    function isIdentityExist(
        address identity
    ) 
        public 
        view 
        returns (bool) 
    {
        if (identity != address(0) && bytes(weidDocuments[identity].metaData.created).length != 0) {
            return true;
        }
        return false;
    }
    
    function isDeactivated(
        address identity
    ) 
        public 
        view 
        returns (bool) 
    {
        if (identity != address(0) && weidDocuments[identity].metaData.deactivated) {
            return true;
    }
        return false;
    }
    
    //resolve the document of the given weid
    function resolve(
        address identity
    )
        public
        view
        returns(
        string memory created, 
        string memory updated, 
        bool deactivated, 
        uint16 versionId, 
        string[] memory authentication, 
        string[] memory service    
    ){
        require(isIdentityExist(identity), "weid not existed!");
        MetaData memory _metaData = weidDocuments[identity].metaData;
        return(_metaData.created, _metaData.updated, _metaData.deactivated, _metaData.versionId, weidDocuments[identity].authentication, weidDocuments[identity].service);
    }
    
    //get weid in weids with the range from first to last
    function getWeId(
        uint256 first,
        uint256 last
    )
        public
        view
        returns(
        address[] memory    
    ){
        require(first >= 0 && last >= first && last < weids.length, "params are invalid!");
        uint256 number = last - first + 1;
        address[] memory weidQuery = new address[](number);
        for(uint256 i=0; i<number; i++){
            weidQuery[i] = weids[first+i];
        }
        return weidQuery;
    }
}
