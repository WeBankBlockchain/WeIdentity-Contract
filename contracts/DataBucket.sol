pragma solidity ^0.4.4;
pragma experimental ABIEncoderV2;

/*
 *       Copyright© (2018-2020) WeBank Co., Ltd.
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
contract DataBucket {
    
    string[] hashList;      // all hash
    
    struct DataStruct {
        string hash;         // the hash
        address owner;        // owner for hash
        address[] useAddress; // the user list for use this hash
        bool isUsed;           // the hash is be useed
        uint256 index;        // the hash index in hashList
        uint256 timestamp;    // the first time for create hash
        mapping(bytes32 => string) extra; //the mapping for store the key--value
    }
    
    mapping(string => DataStruct) hashData; // hash-->DataStruct
    
    address owner;
    
    uint8 constant private SUCCESS = 100;
    uint8 constant private NO_PERMISSION = 101;
    uint8 constant private THE_HASH_DOES_NOT_EXIST = 102;
    uint8 constant private THE_HASH_IS_USED = 103;
    uint8 constant private THE_HASH_IS_NOT_USED = 104;
    
    function DataBucket() public {
        owner = msg.sender;
    }
    
    /**
     * put the key-value into hashData.
     * 
     * @param hash the hash
     * @param key the store key
     * @param value the value of the key
     * @return code the code for result
     */ 
    function put(
        string hash, 
        bytes32 key, 
        string value
    ) 
        public 
        returns (uint8 code) 
    {
        DataStruct storage data = hashData[hash];
        //the first put hash
        if (data.owner == address(0x0)) {
            data.hash = hash;
            data.owner = msg.sender;
            data.timestamp = now;
            pushHash(data);
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
     * push hash into hashList.
     * 
     * @param data the data for hash
     * 
     */ 
    function pushHash(
        DataStruct storage data
    ) 
        internal 
    {
        // find the first empty index.
        int8 emptyIndex = -1;
        for (uint8 i = 0; i < hashList.length; i++) {
            if (isEqualString(hashList[i], "")) {
                emptyIndex = int8(i);
                break;
            }
        }
        // can not find the empty index, push data to last
        if (emptyIndex == -1) {
            hashList.push(data.hash);
            data.index = hashList.length - 1;
        } else {
            // push data by index
            uint8 index = uint8(emptyIndex);
            hashList[index] = data.hash;
            data.index = index;
        }
    }
    
    /**
     * get value by key in the hash data.
     * 
     * @param hash the hash
     * @param key get the value by this key
     * @return value the value
     */ 
    function get(
        string hash, 
        bytes32 key
    ) 
        public view
        returns (uint8 code, string value) 
    {
        DataStruct storage data = hashData[hash];
        if (data.owner == address(0x0)) {
            return (THE_HASH_DOES_NOT_EXIST, "");
        }
        return (SUCCESS, data.extra[key]);
    }
    
    /**
     * remove hash when the key is null, others remove the key
     * 
     * @param hash the hash
     * @param key the key
     * @return the code for result
     */ 
    function removeExtraItem(
        string hash, 
        bytes32 key
    ) 
        public 
        returns (uint8 code) 
    {
        DataStruct memory data = hashData[hash];
        if (data.owner == address(0x0)) {
            return THE_HASH_DOES_NOT_EXIST;
        } else if (msg.sender != data.owner) {
            return NO_PERMISSION;
        } else if (data.isUsed) {
            return THE_HASH_IS_USED;
        } else {
           delete hashData[hash].extra[key];
           return SUCCESS;
        }
    }
    
    /**
     * remove hash when the key is null, others remove the key
     * 
     * @param hash the hash
     * @param force force delete
     * @return the code for result
     */ 
    function removeDataBucketItem(
        string hash,
        bool force
    ) 
        public 
        returns (uint8 code) 
    {
        DataStruct memory data = hashData[hash];
        if (data.owner == address(0x0)) {
            return THE_HASH_DOES_NOT_EXIST;
        } else if (msg.sender == owner && force) {
            delete hashList[data.index];
            delete hashData[hash];
            return SUCCESS;
        } else if (msg.sender != data.owner) {
            return NO_PERMISSION;
        } else if (data.isUsed) {
            return THE_HASH_IS_USED;
        } else {
            delete hashList[data.index];
            delete hashData[hash];
            return SUCCESS;
        }
    }
    
    /**
     * enable the hash.
     * @param hash the hash
     */
    function enableHash(
        string hash
    ) 
        public 
        returns (uint8) 
    {
        DataStruct storage data = hashData[hash];
        if (data.owner == address(0x0)) {
            return THE_HASH_DOES_NOT_EXIST;
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
     * true is THE_HASH_IS_USED, false THE_HASH_IS_NOT_USED.
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
     * disable the hash
     * @param hash the hash
     */
    function disableHash(
        string hash
    ) 
        public 
        returns (uint8) 
    {
        DataStruct storage data = hashData[hash];
        if (data.owner == address(0x0)) {
            return THE_HASH_DOES_NOT_EXIST;
        }
        if (!data.isUsed) {
            return THE_HASH_IS_NOT_USED;
        }
        removeUseAddress(data);
        data.isUsed = hasUse(data);
        return SUCCESS;
    }
    
    /**
     * get all hash by page.
     */ 
    function getAllHash(
        uint8 offset, 
        uint8 num
    ) 
        public 
        view
        returns (string[] hashs, address[] owners, uint256[] timestamps, uint8 nextIndex) 
    {
        hashs = new string[](num);
        owners = new address[](num);
        timestamps = new uint256[](num);
        uint8 index = 0;
        uint8 next = 0;
        for (uint8 i = offset; i < hashList.length; i++) {
            string storage hash = hashList[i];
            if (!isEqualString(hash, "")) {
                DataStruct memory data = hashData[hash];
                hashs[index] = hash;
                owners[index] = data.owner;
                timestamps[index] = data.timestamp;
                index++;
                if (index == num && i != hashList.length - 1) {
                    next = i + 1;
                    break;
                }
            }
        }
        return (hashs, owners, timestamps, next);
    }
    
    function isEqualString(
        string a, 
        string b
    ) 
        private 
        constant 
        returns (bool) 
    {
        if (bytes(a).length != bytes(b).length) {
            return false;
        } else {
            return keccak256(a) == keccak256(b);
        }
    }
    
    /**
     * update the owner of hash
     */
    function updateHashOwner(
        string hash,
        address newOwner
    ) 
        public 
        returns (uint8) 
    {
        // check the hash is exist
        DataStruct storage data = hashData[hash];
        if (data.owner == address(0x0)) {
            return THE_HASH_DOES_NOT_EXIST;
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
     * get use address by hash.
     */ 
    function getUserListByHash(
        string hash,
        uint8 offset, 
        uint8 num
    ) 
        public 
        view
        returns (address[] users, uint8 nextIndex) 
    {
        users = new address[](num);
        uint8 index = 0;
        uint8 next = 0;
        DataStruct memory data = hashData[hash];
        for (uint8 i = offset; i < data.useAddress.length; i++) {
            address user = data.useAddress[i];
            if (user != address(0x0)) {
                users[index] = user;
                index++;
                if (index == num && i != data.useAddress.length - 1) {
                    next = i + 1;
                    break;
                }
            }
        }
        return (users, next);
    }
}