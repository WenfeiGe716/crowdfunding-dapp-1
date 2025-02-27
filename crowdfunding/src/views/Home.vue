<template>
  <div>
    <a-card class="ant-card-shadow">
      <template #title>
        <h3>
          所有投票
          <a-button style="float: right" @click="openModal" type="primary">发起投票</a-button>
        </h3>
      </template>
      <a-table :columns="columns" :loading="state.loading" :data-source="state.data">
        <template #time="{text, record}">
          {{new Date(text * 1000).toLocaleString()}}
        </template>
        <template #tag="{text, record}">
          <a-tag color="success" v-if="record.success === true">
            <template #icon>
              <check-circle-outlined />
            </template>
            投票成功
          </a-tag>
          <a-tag color="processing" v-else-if="new Date(record.endTime * 1000) > new Date()" >
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
        </template>
        <template #action="{text, record}">
          <a @click="clickFunding(record.index)">查看详情</a>
        </template>
      </a-table>
    </a-card>

    <Modal v-model:visible="isOpen">
      <a-card style="width: 600px; margin: 0 2em;" :body-style="{ overflowY: 'auto', maxHeight: '600px' }">
        <template #title><h3 style="text-align: center">发起投票</h3></template>
        <create-form :model="model" :form="form" :fields="fields" />
      </a-card>
    </Modal>
  </div>
</template>

<script lang="ts">
import { defineComponent, ref, reactive } from 'vue';
import Modal from '../components/base/modal.vue'
import CreateForm from '../components/base/createForm.vue'
import { Model, Fields, Form } from '../type/form'
import { contract, getAccount, getAllFundings, Funding, newFunding, addListener } from '../api/contract'
import { message } from 'ant-design-vue'
import { CheckCircleOutlined, SyncOutlined, CloseCircleOutlined } from '@ant-design/icons-vue'
import { useRouter } from 'vue-router'


const columns = [
  {
    dataIndex: 'title',
    key: 'title',
    title: '投票标题'
  },
  {
    title: '目标数票(票)',
    dataIndex: 'goal',
    key: 'goal'
  },
  {
    title: '目前数票(票)',
    dataIndex: 'count',
    key: 'count'
  },
  {
    title: '结束时间',
    dataIndex: 'endTime',
    key: 'endTime',
    slots: { customRender: 'time' }
  },
  {
    title: '当前状态',
    dataIndex: 'success',
    key: 'success',
    slots: { customRender: 'tag' }
  },
  {
    title: '详情',
    dataIndex: 'action',
    key: 'action',
    slots: { customRender: 'action' }
  }
]

export default defineComponent({
  name: 'Home',
  components: { Modal, CreateForm, CheckCircleOutlined, SyncOutlined, CloseCircleOutlined },
  setup() {
    const isOpen = ref<boolean>(false);
    const state = reactive<{loading: boolean, data: Funding[]}>({
      loading: true,
      data: []
    })

    async function fetchData() {
      state.loading = true;
      try {
        state.data = await getAllFundings();
        state.loading = false;
      } catch (e) {
        console.log(e);
        message.error('获取投票失败!');
      }
    }

    async function openModal() {
      model.account = await getAccount();
      isOpen.value = true;
    }
    function closeModal() { isOpen.value = false; }

    const model = reactive<Model>({
      account: '',
      title: '',
      info: '',
      globalPeople: 0,
      initiatorAmount: 0,
      date: null,
    })

    const fields = reactive<Fields>({
      account: {
        type: 'input',
        label: '发起人',
        disabled: true
      },
      title: {
        type: 'input',
        label: '标题',
        rule: {
          required: true,
          trigger: 'blur'
        }
      },
      info: {
        type: 'textarea',
        label: '简介',
        rule: {
          required: true,
          trigger: 'blur'
        }
      },
      globalPeople: {
        type:'number',
        label:'投票人数(票)'
      },
      initiatorAmount: {
        type: 'number',
        label: '押金(ether)',
        min: 0
      },
      date: {
        type: 'time',
        label: '截止日期',
      }
    })

    const form = reactive<Form>({
      submitHint: '发起投票',
      cancelHint: '取消',
      cancel: () => {
        closeModal();
      },
      finish: async () => {
        const seconds = Math.ceil(new Date(model.date).getTime() / 1000);
        try {
          const res = await newFunding(model.account, model.initiatorAmount,model.title, model.info, model.globalPeople, seconds);
          console.log(res)
          message.success('发起投票成功')
          closeModal();
          fetchData();
        } catch(e) {
          console.log(e);
          message.error('发起投票失败')
        }
      }
    })

    const router = useRouter();
    const clickFunding = (index : number) => {
      router.push(`/funding/${index}`)
    }
    addListener(fetchData)
    fetchData();

    return { openModal, isOpen, model, fields, form, state, columns, clickFunding }
  }
});
</script>
