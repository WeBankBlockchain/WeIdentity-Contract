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
contract DataBucket {
    
    string[] bucketIdList;      // all bucketId
    
    struct DataStruct {
        string bucketId;         // the bucketId
        address owner;        // owner for bucket
        address[] useAddress; // the user list for use this bucket
        bool isUsed;           // the bucketId is be useed
        uint256 index;        // the bucketId index in bucketIdList
        uint256 timestamp;    // the first time for create bucketId
        mapping(bytes32 => string) extra; //the mapping for store the key--value
    }
    
    mapping(string => DataStruct) bucketData; // bucketId-->DataStruct
    
    address owner;
    
    uint8 private SUCCESS = 100;
    uint8 private NO_PERMISSION = 101;
    uint8 private THE_BUCKET_DOES_NOT_EXIST = 102;
    uint8 private THE_BUCKET_IS_USED = 103;
    uint8 private THE_BUCKET_IS_NOT_USED = 104;
    
    constructor() public {
        owner = msg.sender;
    }
    
    /**
     * put the key-value into hashData.
     * 
     * @param bucketId the bucketId
     * @param key the store key
     * @param value the value of the key
     * @return code the code for result
     */ 
    function put(
        string memory bucketId, 
        bytes32 key, 
        string memory value
    ) 
        public 
        returns (uint8 code) 
    {
        DataStruct storage data = bucketData[bucketId];
        //the first put bucketId
        if (data.owner == address(0x0)) {
            data.bucketId = bucketId;
            data.owner = msg.sender;
            data.timestamp = block.timestamp;
            pushBucketId(data);
            data.extra[key] = value;
            return SUCCESS;
        } else {
            // no permission
            if (data.owner != msg.sender) {
                 return NO_PERMISSION;
            }
            data.extra[key] = value;
            return SUCCESS;
        }
    }
    
    /**
     * push bucketId into hashList.
     * 
     * @param data the data for bucket
     * 
     */ 
    function pushBucketId(
        DataStruct storage data
    ) 
        internal 
    {
        // find the first empty index.
        int8 emptyIndex = -1;
        for (uint8 i = 0; i < bucketIdList.length; i++) {
            if (isEqualString(bucketIdList[i], "")) {
                emptyIndex = int8(i);
                break;
            }
        }
        // can not find the empty index, push data to last
        if (emptyIndex == -1) {
            bucketIdList.push(data.bucketId);
            data.index = bucketIdList.length - 1;
        } else {
            // push data by index
            uint8 index = uint8(emptyIndex);
            bucketIdList[index] = data.bucketId;
            data.index = index;
        }
    }
    
    function get(
        string memory bucketId, 
        bytes32 key
    ) 
        public view
        returns (uint8 code, string memory value) 
    {
        DataStruct storage data = bucketData[bucketId];
        if (data.owner == address(0x0)) {
            return (THE_BUCKET_DOES_NOT_EXIST, "");
        }
        return (SUCCESS, data.extra[key]);
    }

    function removeExtraItem(
        string memory bucketId, 
        bytes32 key
    ) 
        public 
        returns (uint8 code) 
    {
        DataStruct storage data = bucketData[bucketId];
        if (data.owner == address(0x0)) {
            return THE_BUCKET_DOES_NOT_EXIST;
        } else if (msg.sender != data.owner) {
            return NO_PERMISSION;
        } else if (data.isUsed) {
            return THE_BUCKET_IS_USED;
        } else {
           delete data.extra[key];
           return SUCCESS;
        }
    }

    function removeDataBucketItem(
        string memory bucketId,
        bool force
    ) 
        public 
        returns (uint8 code) 
    {
        DataStruct storage data = bucketData[bucketId];
        if (data.owner == address(0x0)) {
            return THE_BUCKET_DOES_NOT_EXIST;
        } else if (msg.sender == owner && force) {
            delete bucketIdList[data.index];
            delete bucketData[bucketId];
            return SUCCESS;
        } else if (msg.sender != data.owner) {
            return NO_PERMISSION;
        } else if (data.isUsed) {
            return THE_BUCKET_IS_USED;
        } else {
            delete bucketIdList[data.index];
            delete bucketData[bucketId];
            return SUCCESS;
        }
    }
    
    /**
     * enable the bucket.
     * @param bucketId the bucketId
     */
    function enable(
        string memory bucketId
    ) 
        public 
        returns (uint8) 
    {
        DataStruct storage data = bucketData[bucketId];
        if (data.owner == address(0x0)) {
            return THE_BUCKET_DOES_NOT_EXIST;
        }
        
        if (!data.isUsed) {
            data.isUsed = true;
        }
        pushUseAddress(data);
        return SUCCESS;
    }
    
    /**
     * push the user into useAddress.
     */ 
    function pushUseAddress(
        DataStruct storage data
    ) 
        internal 
    {
        int8 emptyIndex = -1;
        for (uint8 i = 0; i < data.useAddress.length; i++) {
            if (data.useAddress[i] == msg.sender) {
                return;
            } 
            if (emptyIndex == -1 && data.useAddress[i] == address(0x0)) {
                emptyIndex = int8(i);
            }
        }
        if (emptyIndex == -1) {
            data.useAddress.push(msg.sender);
        } else {
            data.useAddress[uint8(emptyIndex)] = msg.sender;
        }
    }
    
    /**
     * remove the use Address from DataStruct.
     */ 
    function removeUseAddress(
        DataStruct storage data
    ) 
        internal 
    {
        uint8 index = 0;
        for (uint8 i = 0; i < data.useAddress.length; i++) {
            if (data.useAddress[i] == msg.sender) {
                index = i;
                break;
            }
        }
        delete data.useAddress[index];
    }
    
    /**
     * true is THE_BUCKET_IS_USED, false THE_BUCKET_IS_NOT_USED.
     */
    function hasUse(
        DataStruct storage data
    ) 
        internal 
        view 
        returns (bool)
    {
        for (uint8 i = 0; i < data.useAddress.length; i++) {
            if (data.useAddress[i] != address(0x0)) {
                return true;
            }
        }
        return false;
    }
    
    /**
     * disable the bucket
     * @param bucketId the bucketId
     */
    function disable(
        string memory bucketId
    ) 
        public 
        returns (uint8) 
    {
        DataStruct storage data = bucketData[bucketId];
        if (data.owner == address(0x0)) {
            return THE_BUCKET_DOES_NOT_EXIST;
        }
        if (!data.isUsed) {
            return THE_BUCKET_IS_NOT_USED;
        }
        removeUseAddress(data);
        data.isUsed = hasUse(data);
        return SUCCESS;
    }
    
    /**
     * get all bucket by page.
     */ 
    function getAllBucket(
        uint8 index, 
        uint8 num
    ) 
        public 
        view
        returns (string[] memory bucketIds, address[] memory owners, uint256[] memory timestamps, uint8 nextIndex) 
    {
        bucketIds = new string[](num);
        owners = new address[](num);
        timestamps = new uint256[](num);
        uint8 currentIndex = 0;
        uint8 next = 0;
        for (uint8 i = index; i < bucketIdList.length; i++) {
            string storage bucketId = bucketIdList[i];
            if (!isEqualString(bucketId, "")) {
                bucketIds[currentIndex] = bucketId;
                owners[currentIndex] = bucketData[bucketId].owner;
                timestamps[currentIndex] = bucketData[bucketId].timestamp;
                currentIndex++;
                if (currentIndex == num && i != bucketIdList.length - 1) {
                    next = i + 1;
                    break;
                }
            }
        }
        return (bucketIds, owners, timestamps, next);
    }
    
    function isEqualString(
        string memory a, 
        string memory b
    ) 
        private 
        view 
        returns (bool) 
    {
        if (bytes(a).length != bytes(b).length) {
            return false;
        } else {
            return keccak256(abi.encode(a)) == keccak256(abi.encode(b));
        }
    }
    
    /**
     * update the owner of bucket
     */
    function updateBucketOwner(
        string memory bucketId,
        address newOwner
    ) 
        public 
        returns (uint8) 
    {
        // check the bucketId is exist
        DataStruct storage data = bucketData[bucketId];
        if (data.owner == address(0x0)) {
            return THE_BUCKET_DOES_NOT_EXIST;
        }
        
        // check the owner
        if (msg.sender != owner) {
            return NO_PERMISSION;
        }
        
        if (newOwner != address(0x0)) {
            data.owner = newOwner;
        }
        return SUCCESS;
    }

    /**
     * get use address by bucketId.
     * @param bucketId the bucketId
     * @param index query start index
     * @param num query count
     */ 
    function getActivatedUserList(
        string memory bucketId,
        uint8 index, 
        uint8 num
    ) 
        public 
        view
        returns (address[] memory users, uint8 nextIndex) 
    {
        users = new address[](num);
        uint8 userIndex = 0;
        uint8 next = 0;
        for (uint8 i = index; i < bucketData[bucketId].useAddress.length; i++) {
            address user = bucketData[bucketId].useAddress[i];
            if (user != address(0x0)) {
                users[userIndex] = user;
                userIndex++;
                if (userIndex == num && i != bucketData[bucketId].useAddress.length - 1) {
                    next = i + 1;
                    break;
                }
            }
        }
        return (users, next);
    }
}