import Web3 from 'web3'
//@ts-ignore
import CrowdFunding from './CrowdFunding.json'

//@ts-ignore
const web3 = new Web3(window.ethereum);
const contract = new web3.eth.Contract(CrowdFunding.abi, '0x24198ab5Ad173Be19dA805fcbCd742C634340724');
const magriteContractAddress = '0x9E7A142a48e5c4d07DE06a9BcA18217EC544CB34';
function addListener(fn: Function) {
    //@ts-ignore
    ethereum.on('accountsChanged', fn)
}

export declare interface Funding {
    index: number,
    title: string,
    info: string,
    goal: number,
    endTime: number,
    initiator: string,
    initiatorAmount:number,
    over: boolean,
    success: boolean,
    amount: number,
    numFunders: number,
    numUses: number,
    count:number,
    agreeCount:number,
    disagreeount:number,
    myAmount?: number,
    myFlag?:boolean
}

export declare interface Use {
    index: number,
    info: string,
    agreeCount: string,
    disagreeCount: string,
    over: boolean,
    agree: number // 0: 没决定，1同意，2不同意
}
export declare interface Reward {
    FundingID: number,                  // 投票ID
    payable: string,                    // 发起人
    title: string,                      // 项目标题
    info: string ,                      // 项目简介
    amount: number,                     // 押金数额
    myReward: number,                   // 我的奖励
    agreeCount: number,                 // 同意票数
    disagreeCount: number               // 不同意票数
}
async function authenticate() {
    //@ts-ignore
    await window.ethereum.enable();
}

async function getAccount() {
    return (await web3.eth.getAccounts())[0];
}

async function getAllFundings() : Promise<Funding[]> {
    const length = await contract.methods.numFundings().call();
    const result = []
    for(let i=1; i<=length; i++)
        result.push(await getOneFunding(i));
    return result;
}

async function getBalance() : Promise<string>{
    const balanceWEI = await contract.methods.getBalance().call();
    const balanceETHER = Web3.utils.fromWei(balanceWEI.toString(10), 'ether');
    return balanceETHER;
}

async function getOneFunding(index:number) : Promise<Funding> {
    const data = await contract.methods.fundings(index).call();
    data.amount = Web3.utils.fromWei(data.amount.toString(10), 'ether');
    data.initiatorAmount = Web3.utils.fromWei(data.initiatorAmount.toString(10), 'ether');
    return {index, ...data}
}

async function getMyFundingAmount(index:number) : Promise<number> {
    const account = await getAccount();
    return parseInt(Web3.utils.fromWei(await contract.methods.getMyFundings(account, index).call(), 'ether'));
}
async function getMyFundingFlag(index:number) : Promise<boolean> {
    const account = await getAccount();
    return await contract.methods.getMyFundingsFlag(account, index).call();
}
async function getMyFundings() : Promise<{init: Funding[], contr: Funding[]}> {
    const account = await getAccount();
    const all = await getAllFundings();
    const result : {
        init: Funding[],
        contr: Funding[]
    } = {
        init: [],
        contr: []
    };
    for(let funding of all) {
        const myAmount= await getMyFundingAmount(funding.index);
        const  myFlag = await getMyFundingFlag(funding.index);
        if(funding.initiator == account) {
            result.init.push({
                myAmount,
                myFlag,
                ...funding
            })
        }
        if(myAmount != 0) {
            result.contr.push({
                myAmount,
                myFlag,
                ...funding
            })
        }
    }
    return result;
}

async function contribute(id:number, value:number,flag:boolean) {
    return await contract.methods.contribute(id,flag).send({from: await getAccount(), value: Web3.utils.toWei(value.toString(10), 'ether'), gas: 1000000});
}

async function newFunding(account:string, initiatorAmount:number,title:string, info:string, globalPeople:number, seconds:number) {
    return await contract.methods.newFunding(title, info, globalPeople, seconds).send({
        from: account,
        value: Web3.utils.toWei(initiatorAmount.toString(10), 'ether'),
        gas: 1000000
    });
}
async function recharge(rechargeBalance:number) : Promise<boolean>{
    const balancewe0 = await getBalance();
    await contract.methods.rechargeBalance().send({
        from: await getAccount(),
        value: Web3.utils.toWei(rechargeBalance.toString(10), 'ether'),
        gas: 1000000
    });
    const balancewe1 = await getBalance();

    return parseInt(balancewe0)+rechargeBalance == parseInt(balancewe1);
}
async function getAllUse(id:number) : Promise<Use[]> {
    const length = await contract.methods.getUseLength(id).call();
    const account = await getAccount();
    const rusult : Use[] = []
    for(let i=1; i<=length; i++) {
        const use = await contract.methods.getUse(id, i, account).call();
        rusult.push({
            index: i,
            info: use[0],
            agreeCount: use[1],
            disagreeCount: use[2],
            over: use[3],
            agree: use[4]
        });
    }
    return rusult;
}

async function agreeUse(id:number, useID: number, agree:boolean) {
    const accont = await getAccount();
    return await contract.methods.agreeUse(id, useID, agree).send({
        from: accont,
        gas: 1000000
    })
}

async function newUse(id:number,  info:string) {
    const account = await getAccount();
    return await contract.methods.newUse(id, info).send({
        from: account,
        gas: 1000000
    })
}

async function returnMoney(id: number) {
    const account = await getAccount();
    return await contract.methods.returnMoney(id).send({
        from: account,
        gas: 1000000
    })
}

async function returnMoneyE(id: number) {
    const account = await getAccount();
    return await contract.methods.returnMoneyE(id).send({
        from: account,
        gas: 1000000
    })
}

async function withdrawReward(id: number) {
    const account = await getAccount();
    return await contract.methods.withdrawReward(id).send({
        from: account,
        gas: 1000000
    })
}

async function myReward(): Promise<Reward[]> {
    const account = await getAccount();
    const rewardsLength = await contract.methods.getRewardsLength();
    const rewards = [];
    for (let i = 0;i < rewardsLength;i++) {
        const reward = await contract.methods.rewards[account][i];
        reward.amount = Web3.utils.fromWei(reward.amount.toString(10), 'ether');
        reward.myReward = Web3.utils.fromWei(reward.myReward.toString(10), 'ether');
        rewards.push(reward);
    }
    return rewards;
}

export {
    getAccount,
    getBalance,
    authenticate,
    contract,
    getAllFundings,
    getOneFunding,
    getMyFundingAmount,
    getMyFundingFlag,
    magriteContractAddress,
    contribute,
    newFunding,
    recharge,
    getAllUse,
    agreeUse,
    newUse,
    getMyFundings,
    returnMoney,
    returnMoneyE,
    withdrawReward,
    addListener,
    myReward
}
