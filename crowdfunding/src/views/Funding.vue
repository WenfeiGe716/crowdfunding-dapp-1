<template>
  <div>
    <a-card
      class="ant-card-shadow"
      :loading="state.loading"
      :tab-list="tabList"
      :active-tab-key="key"
      @tabChange="onTabChange"
    >
      <template #title>
        <h3>
          {{state.data.title}}
          <span style="float:right">
            <span v-if="state.myAmount != 0">
              <span v-if="state.flag">
                您投票了同意票
              </span>
              <span v-if="!state.flag">
                您投票了拒绝票
              </span>
              <span v-if="state.data.success == true && state.data.agreeCount > state.data.disagreeCount && state.flag">
                得到 {{state.myAmount}}(押金) * 2 ether 奖励
              </span>
              <span v-if="state.data.success == true && state.data.agreeCount > state.data.disagreeCount && !state.flag">
                没有得到 ether 奖励
              </span>
              <span v-if="state.data.success == true && state.data.agreeCount < state.data.disagreeCount && state.flag">
                没有得到 ether 奖励
              </span>
              <span v-if="state.data.success == true && state.data.agreeCount < state.data.disagreeCount && !state.flag">
                得到 {{state.myAmount}}(押金) * 2 ether 奖励
              </span>
              <span v-if="state.data.success == false ">
                预计得到 {{state.myAmount}}(押金) * 2 ether 奖励
              </span>
            </span>
            <span v-if="account == state.data.initiator">
              <span v-if="state.data.success == true && state.data.agreeCount > state.data.global/2 ">
                得到 {{state.data.initiatorAmount}} ether(押金) * 5 ether 奖励
              </span>

              <span v-if="state.data.success == true && state.data.agreeCount < state.data.global/2 ">
                没有得到 ether 奖励
              </span>
              <span v-if="state.data.success == false ">
                预计得到 {{state.data.initiatorAmount}} ether(押金) * 5 ether 奖励
              </span>
            </span>
            <a-button type="primary" v-if="state.data.success == true && state.data.agreeCount == state.data.disagreeCount " @click="returnME()">平票退钱</a-button>
            <a-button type="primary" v-if="new Date(state.data.endTime * 1000) > new Date() && state.data.success == false && state.myAmount == 0 && account != state.data.initiator" @click="openModal">我要投票</a-button>
            <a-button type="danger" v-if="!state.data.success && new Date(state.data.endTime * 1000) < new Date()" @click="returnM">超时退钱！</a-button>
            <a-button type="danger" v-if="(state.data.success && state.data.agreeCount > state.data.disagreeCount && state.flag && state.data.amount != 0) || (state.data.success && state.data.agreeCount < state.data.disagreeCount && !state.flag && state.data.amount != 0)" @click="withdraw">提取奖励</a-button>
          </span>
        </h3>
      </template>
      <a-descriptions bordered v-if="key==='info'">
        <a-descriptions-item label="投票标题" :span="2">
          {{state.data.title}}
        </a-descriptions-item>
        <a-descriptions-item label="投票发起人" :span="2">
          {{state.data.initiator}}
        </a-descriptions-item>
        <a-descriptions-item label="截止日期" :span="2">
           {{new Date(state.data.endTime * 1000).toLocaleString()}}
        </a-descriptions-item>
        <a-descriptions-item label="当前状态">
          <a-tag color="success" v-if="state.data.success === true">
            <template #icon>
              <check-circle-outlined />
            </template>
            投票成功
          </a-tag>
          <a-tag color="processing" v-else-if="new Date(state.data.endTime * 1000) > new Date()" >
            <template #icon>
              <sync-outlined :spin="true" />
            </template>
            正在投票
          </a-tag>
          <a-tag color="error" v-else>
            <template #icon>
              <close-circle-outlined />
            </template>
            投票失败
          </a-tag>
        </a-descriptions-item>
        <a-descriptions-item label="目标票数">
          <a-statistic :value="state.data.goal">
            <template #suffix>
              票
            </template>
          </a-statistic>
        </a-descriptions-item>
        <a-descriptions-item label="当前票数">
          <a-statistic :value="state.data.count">
            <template #suffix>
              票
            </template>
          </a-statistic>
        </a-descriptions-item>
        <a-descriptions-item label="投票进度">
          <a-progress type="circle" :percent="state.data.success ? 100 : Math.trunc(state.data.count * 100 / state.data.goal)" :width="80" />
        </a-descriptions-item>
        <a-descriptions-item v-if="state.data.success" label="同意票数">
          <a-statistic :value="state.data.agreeCount">
            <template #suffix>
              票
            </template>
          </a-statistic>
        </a-descriptions-item>
        <a-descriptions-item v-if="state.data.success" label="拒绝票数">
          <a-statistic :value="state.data.disagreeCount">
            <template #suffix>
              票
            </template>
          </a-statistic>
        </a-descriptions-item>
        <a-descriptions-item label="押金">
          <a-statistic v-if="account.value == state.data.initiator" :value="state.data.initiatorAmount">
            <template #suffix>
              ether
            </template>
          </a-statistic>
          <a-statistic v-if="account.value != state.data.initiator" :value="state.data.amount">
            <template #suffix>
              ether
            </template>
          </a-statistic>
        </a-descriptions-item>
        <a-descriptions-item label="投票介绍">
          {{state.data.info}}
        </a-descriptions-item>
      </a-descriptions>

      <Use v-if="key==='use'" :id="id" :data="state.data" :amount="state.myAmount"></Use>

    </a-card>

    <Modal v-model:visible="isOpen">
      <a-card style="width: 600px; margin: 0 2em;" :body-style="{ overflowY: 'auto', maxHeight: '600px' }">
        <template #title><h3 style="text-align: center">投票</h3></template>
        <create-form :model="model" :form="form" :fields="fields" />
      </a-card>
    </Modal>
  </div>
</template>

<script lang="ts">
import { defineComponent, ref, reactive, computed } from 'vue';
import { getOneFunding, Funding, getAccount, getMyFundingAmount, getMyFundingFlag,contribute, returnMoney, addListener, returnMoneyE, withdrawReward} from '../api/contract'
import { useRoute } from 'vue-router'
import { message } from 'ant-design-vue';
import { CheckCircleOutlined, SyncOutlined, CloseCircleOutlined } from '@ant-design/icons-vue'
import Modal from '../components/base/modal.vue'
import CreateForm from '../components/base/createForm.vue'
import Use from '../components/Use.vue'
import { Model, Fields, Form } from '../type/form'

const column = [
  {
    dataIndex: ''
  }
]

const tabList = [
  {
    key: 'info',
    tab: '项目介绍',
  },
  // {
  //   key: 'use',
  //   tab: '提取奖励',
  // },
];

export default defineComponent({
  name: 'Funding',
  components: { Modal, CreateForm, CheckCircleOutlined, SyncOutlined, CloseCircleOutlined, Use },
  setup() {
    // =========基本数据==========
    const route = useRoute();
    const id = parseInt(route.params.id as string);
    const account = ref('');
    const state = reactive<{data: Funding | {}, loading: boolean, myAmount: number, flag:boolean}>({
      data: {},
      loading: true,
      myAmount: 0,
      flag: false
    })

    // ===========发起投票表单============
    const isOpen = ref(false);
    function openModal() { isOpen.value = true }
    function closeModal() { isOpen.value = false }

    const model = reactive<Model>({
      amountValue: 1,
      flag: 0
    })
    const fields = reactive<Fields>({
      amountValue: {
        type: 'number',
        label: '押金'
      },
      flag: {
        type: 'radio',
        label: '投票',
        radios: [{hint:"同意",value:1},{hint:"拒绝",value:0}]
      }
    })
    const form = reactive<Form>({
      submitHint: '投票',
      cancelHint: '取消',
      cancel: () => {
        closeModal();
      },
      finish: async () => {
        try {
          await contribute(id, model.amountValue, model.flag);
          message.success('投票成功')
          fetchData();
          closeModal();
        } catch (e) {
          message.error('投票失败')
        }
      }
    })

    async function returnM() {
      try {
        await returnMoney(id);
        message.success('退钱成功');
        fetchData()
      } catch(e) {
        message.error('退钱失败')
      }
    }

    async function returnME() {
      try {
        await returnMoneyE(id);
        message.success('退钱成功');
        fetchData()
      } catch(e) {
        message.error('退钱失败')
      }
    }

    async function withdraw() {
      try {
        await withdrawReward(id);
        message.success('提取成功');
        fetchData()
      } catch(e) {
        message.error('提取失败')
      }
    }
    // =========切换标签页===========
    const key = ref('info');
    const onTabChange = (k : 'use' | 'info') => {
      key.value = k;
    }

    // =========加载数据===========
    async function fetchData() {
      state.loading = true;
      try {
        [state.data, state.myAmount, state.flag] = await Promise.all([getOneFunding(id), getMyFundingAmount(id), getMyFundingFlag(id)]);
        state.loading = false;
        //@ts-ignore
        // fields.value.max = state.data.goal - state.data.count;
      } catch (e) {
        console.log(e);
        message.error('获取详情失败');
      }
    }

    addListener(fetchData)

    getAccount().then(res => account.value = res)
    fetchData();

    return {state, account, isOpen, openModal, form, model, fields, tabList, key, onTabChange, id, returnM, withdraw, returnME}
  }
});
</script>
