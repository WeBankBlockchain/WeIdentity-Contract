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
