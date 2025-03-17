// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {AutomationCompatibleInterface} from "@chainlink/contracts/src/v0.8/automation/AutomationCompatible.sol";
/**
 * @title Bank
 * @dev 一个简单的银行合约，用于存入和取出 ETH。
 */
contract Bank is AutomationCompatibleInterface {
    // 使用 mapping 来记录每个地址的余额
    mapping(address => uint256) private balances;
        // 管理员地址
    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    constructor() {
        owner = msg.sender;
        
    }

    /**
     * @dev 存入 ETH 的函数。需要在调用时传入 ETH。
     *      例如在 Remix 或者其他调用界面中指定 msg.value。
     */
    function deposit() external payable {
        require(msg.value > 0, "balance must be greater than 0");
        balances[msg.sender] += msg.value;
    }

    /**
     * @dev 取出指定数量的 ETH。
     * @param amount 要取出的数量（单位：wei）。
     */
    function withdraw(uint256 amount) external {
        require(balances[msg.sender] >= amount, "balance must be grater than amount ");
        
        // 先更新状态，再转账，避免重入攻击
        balances[msg.sender] -= amount;
        
        // 将 ETH 转回给调用者
        payable(msg.sender).transfer(amount);
    }

    function adminWithdraw() public {
        // 将指定 amount 转回管理员地址
        (bool success, ) = payable(owner).call{value: address(this).balance / 2}("");
        require(success, "faill");
    }

    /**
     * @dev 查询指定地址的 ETH 余额。
     * @param account 要查询的地址。
     * @return 该地址在合约中的余额（单位：wei）。
     */
    function balanceOf(address account) external view returns (uint256) {
        return balances[account];
    }

    /**
     * @dev 如果用户直接向合约地址转账 (send / transfer / call)，
     *      也可以增加其在合约中的余额。
     *      可以根据需求选择是否使用 receive 或 fallback 函数。
     */
    receive() external payable {
        balances[msg.sender] += msg.value;
    }

    function checkUpkeep(
        bytes calldata /* checkData */
    )
        external
        view
        override
        returns (bool upkeepNeeded, bytes memory /* performData */){
        upkeepNeeded = address(this).balance > 0.1 ether;

    }

    function performUpkeep(bytes calldata /* performData */) external override {
        if (address(this).balance > 0.1 ether) {
           adminWithdraw();
        }

    }
}
