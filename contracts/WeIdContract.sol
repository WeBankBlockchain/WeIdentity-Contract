pragma solidity ^0.4.4;
/*
 *       Copyright© (2018) WeBank Co., Ltd.
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

contract WeIdContract {

    mapping(address => uint) changed;

    // Authorization related functions
    mapping(address => mapping(address => bool)) authorized;
    mapping(address => bool) selfRevoked;

    modifier onlyOwner(address identity, address actor) {
        require ((actor == identity && selfRevoked[actor] == false) || authorized[identity][actor] == true);
        _;
    }

    bytes32 constant private WEID_KEY_CREATED = "created";
    bytes32 constant private WEID_KEY_AUTHENTICATION = "/weId/auth";
    uint constant private WEID_AUTHORIZE_ADD = 0;
    uint constant private WEID_AUTHORIZE_REVOKE = 1;

    event WeIdAttributeChanged(
        address indexed identity,
        bytes32 key,
        bytes value,
        uint previousBlock,
        int updated
    );

    event WeIdAuthorize(
        uint type,
        address from,
        address to,
        uint currentBlock
    )

    function addAuthorize(address to) public onlyOwner(to, msg.sender) {
        // The first call will require strict ownership
        if (msg.sender == to) {
            selfRevoked[msg.sender] = true;
        } else {
            authorized[msg.sender][to] = true;
        }
        WeIdAuthorize(WEID_AUTHORIZE_ADD, msg.sender, to, block.number);
    }

    funciton revokeAuthorize(address to) public onlyOwner(to, msg.sender) {
        if (msg.sender == to) {
            selfRevoked[msg.sender] = false;
        } else {
            authorized[msg.sender][to] = false;
        }
        WeIdAuthorize(WEID_AUTHORIZE_REVOKE, msg.sender, to, block.number);
    }

    function getLatestRelatedBlock(
        address identity
    ) 
        public 
        constant 
        returns (uint) 
    {
        return changed[identity];
    }

    function createWeId(
        address identity,
        bytes auth,
        bytes created,
        int updated
    )
        public
        onlyOwner(identity, msg.sender)
    {
        WeIdAttributeChanged(identity, WEID_KEY_CREATED, created, changed[identity], updated);
        WeIdAttributeChanged(identity, WEID_KEY_AUTHENTICATION, auth, changed[identity], updated);
        changed[identity] = block.number;
    }

    function setAttribute(
        address identity, 
        bytes32 key, 
        bytes value, 
        int updated
    ) 
        public 
        onlyOwner(identity, msg.sender)
    {
    	WeIdAttributeChanged(identity, key, value, changed[identity], updated);
        changed[identity] = block.number;
    }
    
    function isIdentityExist(
        address identity
    ) 
        public 
        constant 
        returns (bool) 
    {
        if (0x0 != identity && 0 != changed[identity]) {
            return true;
    }
        return false;
    }
}