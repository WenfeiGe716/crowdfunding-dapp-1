// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract CrowdFunding {

  // 投票人结构定义
  struct Funder {
    address payable addr;   // 投票人的地址
    uint amount;            // 押金数额
    bool flag;              // 同意或者拒绝
  }

  // 资金使用请求结构定义
  struct Use {
    string info;                     // 使用请求的说明
    uint agreeCount;                 // 目前的同意数额
    uint disagreeCount;              // 目前的不同意数额
    bool over;                       // 请求是否结束
    mapping(uint => uint) agree;     // 出资人是否同意 0: 还没决定，1：同意，2：不同意
  }

  // 投票项目的结构定义
  struct Funding {
    address payable initiator;       // 发起人
    string title;                    // 项目标题
    string info;                     // 项目简介
    uint goal;                       // 目标票数
    uint endTime;                    // 投票结束时间

    bool success;                    // 投票是否成功

    uint256 amount;                     // 当前已经获得的押金数额
    uint256 initiatorAmount;            // 发起人的押金

    uint numFunders;                 // 投票记录数量
    uint numUses;                    // 使用请求数量
    uint count;                      // 当前投票总量
    uint agreeCount;                 // 当前同意票数
    uint disagreeCount;              // 当前不同意票数
    mapping(uint => Funder) funders; // 投票记录具体信息
    mapping(uint => Use) uses;       // 所有的申请提取奖金请求
  }

  struct Rewards {
    uint FundingID;                  // 投票ID
    address payable initiator;       // 发起人
    string title;                    // 项目标题
    string info;                     // 项目简介
    uint256 amount;                     // 押金数额
    uint256 myReward;                   // 我的奖励
    uint agreeCount;                 // 同意票数
    uint disagreeCount;              // 不同意票数
  }

  uint public numFundings;                  // 投票项目数量
  mapping(uint => Funding) public fundings; // 所有的投票项目
  mapping(address => Rewards []) public rewards; // 所有奖励
  address admin = 0x33827106E00Cd84f614fa91596429b1268e22a46;

  function getRewardsLength() public view returns(uint) {
    return rewards[msg.sender].length;
  }
  /**
   * 发起投票项目
   * @param title 项目标题
   * @param info 项目简介
   * @param goal 目标票数
   * @param endTime 结束时间
   */
  function newFunding(string memory title, string memory info, uint goal, uint endTime) public payable returns(uint) {
    require(endTime > block.timestamp);

    numFundings = numFundings + 1;
    Funding storage f = fundings[numFundings];
    f.initiator = msg.sender;
    f.initiatorAmount = msg.value;
    f.title = title;
    f.info = info;
    f.goal = goal;
    f.endTime = endTime;
    f.success = false;
    f.amount = 0;
    f.numFunders = 0;
    f.numUses = 0;
    f.count = 0;
    f.agreeCount = 0;
    f.disagreeCount = 0;

    return numFundings;
  }

  function contribute(uint ID,bool flag) public payable {
    // 押金必须大于0，不能超过5
    require(msg.value > 0 ether && msg.value <= 5 ether, "押金不合法！");
    // 时间上必须还没结束
    require(fundings[ID].endTime > block.timestamp , "时间已经截止！");
    // 必须是未完成的投票
    require(fundings[ID].success == false , "投票已完成！");
    // 投票人必须是首次投票
    for(uint i = 1; i <= fundings[ID].numFunders; i++){
      require(fundings[ID].funders[fundings[ID].numFunders].addr != msg.sender, "您已参与过投票！");
    }


    Funding storage f = fundings[ID];
    f.amount += msg.value;
    f.count += 1;
    if (flag) {
      f.agreeCount += 1;
    }
    if (!flag) {
      f.disagreeCount += 1;
    }
    f.numFunders = f.numFunders + 1;
    f.funders[f.numFunders].addr = msg.sender;
    f.funders[f.numFunders].amount = msg.value;
    f.funders[f.numFunders].flag = flag;
    // 考虑本项目是否达成目标
    f.success = f.count >= f.goal;
  }

  // 平票退钱
  function returnMoneyE(uint ID) public {
    require(ID <= numFundings && ID >= 1);
    require(fundings[ID].success == true);
    require(fundings[ID].amount > 0);
    require(fundings[ID].disagreeCount == fundings[ID].agreeCount);
    Funding storage f = fundings[ID];

    uint256 initiatorAmount = f.initiatorAmount;
    uint256 amount;
    f.initiatorAmount = 0;
    f.amount = 0;
    // 押金退回
    f.initiator.transfer(initiatorAmount);
    for(uint i=1; i<=f.numFunders; i++) {
      amount = f.funders[i].amount;
      f.funders[i].addr.transfer(amount);
    }

  }
  // 超时退钱
  function returnMoney(uint ID) public {
    require(ID <= numFundings && ID >= 1);
    Funding storage f = fundings[ID];
    uint256 initiatorAmount = f.initiatorAmount;
    uint256 amount;
    f.amount = 0;
    f.initiatorAmount = 0;
    // 押金退回
    f.initiator.transfer(initiatorAmount);
    for(uint i=1; i<=f.numFunders; i++) {
      amount = f.funders[i].amount;
      f.funders[i].addr.transfer(amount);
    }
  }

  //提取奖励
  function withdrawReward(uint ID) public {
    require(ID <= numFundings && ID >= 1);
    require(fundings[ID].amount > 0);
    uint256 initiatorAmount = fundings[ID].initiatorAmount;
    uint256 amount;
    fundings[ID].initiatorAmount = 0;
    fundings[ID].amount = 0;
    if (fundings[ID].success && fundings[ID].disagreeCount < fundings[ID].agreeCount) {
      // 提取奖励 5 倍
      fundings[ID].initiator.transfer(initiatorAmount*5);
      Rewards memory reward1 = Rewards(ID,fundings[ID].initiator,fundings[ID].title, fundings[ID].info, initiatorAmount, initiatorAmount*5, fundings[ID].agreeCount, fundings[ID].disagreeCount);
      rewards[fundings[ID].initiator].push(reward1);
      for(uint i=1; i<=fundings[ID].numFunders; i++) {
        amount = fundings[ID].funders[i].amount;
        // 奖励押金的2倍
        if (fundings[ID].funders[i].flag){
          fundings[ID].funders[i].addr.transfer(amount*2);
          Rewards memory reward2 = Rewards(ID,fundings[ID].initiator,fundings[ID].title, fundings[ID].info, amount, amount*2, fundings[ID].agreeCount, fundings[ID].disagreeCount);
          rewards[fundings[ID].funders[i].addr].push(reward2);
        }
        amount = 0;
      }
    }
    if (fundings[ID].success && fundings[ID].disagreeCount > fundings[ID].agreeCount) {
      for(uint i=1; i<=fundings[ID].numFunders; i++) {
        amount = fundings[ID].funders[i].amount;
        // 奖励押金的2倍
        if (!fundings[ID].funders[i].flag){
          fundings[ID].funders[i].addr.transfer(amount*2);
          Rewards memory reward3 = Rewards(ID,fundings[ID].initiator,fundings[ID].title, fundings[ID].info, amount, amount*2, fundings[ID].agreeCount, fundings[ID].disagreeCount);
          rewards[fundings[ID].funders[i].addr].push(reward3);
        }
        amount = 0;
      }
    }

  }

  function newUse(uint ID, string memory info) public {
    require(ID <= numFundings && ID >= 1);
    require(fundings[ID].success == true);
    require(msg.sender == fundings[ID].initiator);

    Funding storage f = fundings[ID];
    f.numUses = f.numUses + 1;
    f.uses[f.numUses].info = info;
    f.uses[f.numUses].agreeCount = 0;
    f.uses[f.numUses].disagreeCount = 0;
    f.uses[f.numUses].over = false;
  }

  function agreeUse(uint ID, uint useID, bool agree) public {
    require(ID <= numFundings && ID >= 1);
    require(useID <= fundings[ID].numUses && useID >= 1);
    require(fundings[ID].uses[useID].over == false);

    for(uint i=1; i<=fundings[ID].numFunders; i++)
      if(fundings[ID].funders[i].addr == msg.sender) {
        if(agree) {
          fundings[ID].uses[useID].agreeCount += 1;
          fundings[ID].uses[useID].agree[i] = 1;
        }
        else {
          fundings[ID].uses[useID].disagreeCount += 1;
          fundings[ID].uses[useID].agree[i] = 2;
        }
      }
    checkUse(ID, useID);
  }

  function checkUse(uint ID, uint useID) public {
    require(ID <= numFundings && ID >= 1);
    require(fundings[ID].uses[useID].over == false);

    // 提取奖励 5 倍
    uint256 initiatorAmount = fundings[ID].initiatorAmount;
    uint256 amount;
    if(fundings[ID].uses[useID].agreeCount >= fundings[ID].count / 2) {
      fundings[ID].uses[useID].over = true;
      // 提取奖励 5 倍
      fundings[ID].initiatorAmount = 0;
      fundings[ID].initiator.transfer(initiatorAmount*5);
      for(uint i=1; i<=fundings[ID].numFunders; i++)
        if(fundings[ID].funders[i].addr == msg.sender) {
          amount = fundings[ID].funders[i].amount;
          fundings[ID].amount -= fundings[ID].funders[i].amount;
          // 奖励押金的2倍
          if (fundings[ID].funders[i].flag){
            fundings[ID].funders[i].addr.transfer(amount*2);
          }

          fundings[ID].amount -= fundings[ID].funders[i].amount;
        }
    }
    if(fundings[ID].uses[useID].disagreeCount > fundings[ID].count / 2) {
      fundings[ID].uses[useID].over = true;
      fundings[ID].initiatorAmount = 0;
      for(uint i=1; i<=fundings[ID].numFunders; i++)
        if(fundings[ID].funders[i].addr == msg.sender) {
          amount = fundings[ID].funders[i].amount;
          fundings[ID].amount -= fundings[ID].funders[i].amount;
          // 奖励押金的2倍
          if (!fundings[ID].funders[i].flag){
            fundings[ID].funders[i].addr.transfer(amount*2);
          }
        }
    }
  }

  function getUseLength(uint ID) public view returns (uint) {
    require(ID <= numFundings && ID >= 1);
    return fundings[ID].numUses;
  }

  function getUse(uint ID, uint useID, address addr) public view returns (string memory, uint, uint, bool, uint) {
    require(ID <= numFundings && ID >= 1);

    Use storage u = fundings[ID].uses[useID];
    uint agree = 0;
    for(uint i=1; i<=fundings[ID].numFunders; i++)
      if(fundings[ID].funders[i].addr == addr) {
        agree = fundings[ID].uses[useID].agree[i];
        break;
      }
    return (u.info, u.agreeCount, u.disagreeCount, u.over, agree);
  }

  function getBalance() public view returns (uint) {
    return address(this).balance;
  }

  function withdrawBalance() public {
    require(msg.sender == admin);
    msg.sender.transfer(address(this).balance);
  }

  function getMyFundings(address addr, uint ID) public view returns (uint) {
    uint res = 0;
    for(uint i=1; i<=fundings[ID].numFunders; i++) {
      if(fundings[ID].funders[i].addr == addr)
        res += fundings[ID].funders[i].amount;
    }
    return res;
  }
  function getMyFundingsFlag(address addr, uint ID) public view returns (bool) {
    bool res = false;
    for(uint i=1; i<=fundings[ID].numFunders; i++) {
      if(fundings[ID].funders[i].addr == addr)
        res = fundings[ID].funders[i].flag;
    }
    return res;
  }

  function rechargeBalance() public payable returns(uint256) {
    return msg.value;
  }

  fallback() external payable {}

  receive() external payable {}
}
