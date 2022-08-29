### V1.2.30 (2021-04-15)
* 新增
1. Authority支持查询已认证的权威机构总数。
2. SpecificIssuer支持分页查询Type列表以及删除Type。


### V1.2.12 (2020-01-2)
* 新增
1. CPT合约支持零知识证明的credential template的读写。

* 修正：
1. 解决了Evidence合约里setHash的bug。

* Added:
1. support credential template in CptController contract.

* Bugfixes:
1. Fix bug of setHash() method in Evidence contract.


### V1.2.3 (2019-06-27)
* 修正：
1. 修改了weIdContract的合约格式。
2. 修改了工程名，对应的java版本的release由weidentity-contract-java改为weid-contract-java。
3. UpdateCpt()增加了权限控制，现在必须要拥有管理员权限或是注册者本人才能更新。

* Bugfixes:
1. WeIdContract code re-formatted.
2. Project name changed from "weidentity-" to "weid-".
3. UpdateCpt() now requires permission - only the publisher or the administrator can perform this.

### V1.2.2 (2019-05-21)
* 新增：
1. WeIdContract新增createWeId方法，支持在创建WeIdentity DID时设置公钥

* Added:
1. WeIdContract now has a new createWeId() method to automatically set public keys and authentication type.

### V1.2.1 (2019-05-15)
* 修正：
1. 修改了CptController的构造方法，保证后向兼容性

* Bugfixes：
1. Reverted the constructor of CptController to ensure backward compatibility.

### V1.2.0 (2019-05-10)
* 新增：
1. SpecificIssuer数据合约及逻辑合约，用于在链上登记特定类型issuer角色
2. CPT新增注册接口，允许在注册时指定CPT ID

* 修正：
1. 大幅度提升了Committee及AuthorityIssuer相关实现的性能
2. AuthorityIssuer的机构名现在是唯一的

* Added:
1. Smart Contract for Specific Issuer management, allowing registering specific issuer roles on blockchain.
2. New interfaces to register CPT with a specified CPT ID.

* Bugfixes:
1. Significantly improved the performance of related implementations in Committee and AuthorityIssuer.
2. Authority Issuer names are now unique.

### V1.1.0 (2019-01-30)

* 新增：
1. Evidence存证数据及工厂合约

* Added:
1. Smart Contract for Evidence management, including data & factory contracts.

### V1.0.0 (2018-10-30)

* 新增:
1. WeId身份管理合约，支持符合FISCO-BCOS外部账户格式的地址作为身份标识
2. Committee数据合约以及逻辑合约
3. AuthorityIssuer权威Issuer数据合约及逻辑合约
4. CPT数据合约及逻辑合约

* Added:
1. Smart Contract for DID identity management, allowing external addresses which satisfy FISCO-BCOS specifications to be used as the identification tag.
2. Smart Contract for Committee Membership management, including data & logic contracts.
3. Smart Contract for Authority Issuer Membership management, including data & logic contracts.
4. Smart Contract for Claim Protocol Type (CPT) management, including data & logic contracts.
