<template>
  <header>
    <nav :class="['nav', {'nav-active': scrollTop > 0}]">
      <a class="logo"><img src="/logo.png"></a>
      <router-link to="/">所有投票</router-link>
      <router-link to="/myself">我的投票</router-link>
      <router-link to="/myReward">我的奖励</router-link>
      <span :style="{ flex: 1 }"></span>
      <a @click="handleClick">{{account}} </a>
      <a v-if="magriteContractAddress == account">身份：合约管理员</a>
      <a v-if="magriteContractAddress == account">合约余额：{{balance}} ether</a>
      <a-button v-if="magriteContractAddress == account" style="float: right" @click="openModal" type="primary">充值</a-button>
    </nav>
    <h1 class="title">
      Dapp投票平台
    </h1>
  </header>
  <div>
    <Modal v-model:visible="isOpen">
      <a-card style="width: 600px; margin: 0 2em;" :body-style="{ overflowY: 'auto', maxHeight: '600px' }">
        <template #title><h3 style="text-align: center">充值</h3></template>
        <create-form :model="model" :form="form" :fields="fields" />
      </a-card>
    </Modal>
  </div>
</template>

<script lang="ts">
import {ref, onMounted,  defineComponent, reactive} from 'vue'
import Modal from '../components/base/modal.vue'
import CreateForm from '../components/base/createForm.vue'
import {message} from 'ant-design-vue'
import {authenticate, getAccount, addListener, getBalance, recharge, magriteContractAddress} from '../api/contract'
import {Fields, Form, Model} from "@/type/form";

export default defineComponent({
  components: { Modal, CreateForm },
  setup() {
    // 滚动事件
    const scrollTop = ref(0)
    const isOpen = ref<boolean>(false);
    onMounted(() => {
      window.addEventListener('scroll', () => {
        scrollTop.value = window.pageYOffset || document.documentElement.scrollTop || document.body.scrollTop
      })
    })
    // 认证
    const account = ref('认证');
    const balance = ref();
    async function handleClick() {
      await authenticate();
      account.value = await getAccount();
      balance.value = await getBalance();
    }
    handleClick();
    addListener(handleClick);

    async function openModal() {
      model.account = await getAccount();
      isOpen.value = true;
    }
    function closeModal() { isOpen.value = false; }
    const model = reactive<Model>({
      rechargeBalance: 0
    })

    const fields = reactive<Fields>({

      rechargeBalance: {
        type: 'number',
        label: '充值(ether)',
        min: 0
      }
    })

    const form = reactive<Form>({
      submitHint: '发起充值',
      cancelHint: '取消',
      cancel: () => {
        closeModal();
      },
      finish: async () => {
        try {
          const res = await recharge(model.rechargeBalance);
          console.log(res)
          message.success('充值成功')
          closeModal();
          // 刷新页面
          handleClick();
          addListener(handleClick);
        } catch(e) {
          console.log(e);
          message.error('充值失败')
        }
      }
    })
    return {scrollTop, handleClick, account, balance, openModal, isOpen, model, fields, form, magriteContractAddress}
  }

})
</script>

<style scoped>
header {
  height: 200px;
  background: url("/header.png") no-repeat top/cover;
}
header .nav {
  display: flex;
  align-items: center;
  padding: 0 10em;
  position: fixed;
  left: 0;
  right: 0;
  transition: all 0.3s ease;
  z-index: 10;
}
@media screen and (max-width: 800px) {
  header .nav {
    padding: 0;
  }
}
header .nav a {
  line-height: 50px;
  padding: 0 1em;
  border: 3px solid transparent;
  color: white;
  transition: all 0.3s ease;
}
header .nav a:hover {
  background: var(--hover-background);
  border-top-color: var(--hover-color);
}
header .nav a.router-link-active, header .nav a.router-link-exact-active {
  border-top-color: var(--choose-color);
}
header .nav a.logo {
  padding: 0;
}
header .nav a.logo img {
  width: 0;
  height: 50px;
  opacity: 0;
  transition: all 0.3s ease;
}
header .nav:hover, header .nav.nav-active {
  background: #fff;
  box-shadow: var(--shadow);
}
header .nav:hover a, header .nav.nav-active a {
  color: #333;
}
header .nav.nav-active a.logo {
  padding: 0 1em;
}
header .nav.nav-active a.logo img {
  width: 50px;
  opacity: 1;
}
.title {
  position: absolute;
  left: 4em;
  top: 3em;
  color: white;
  text-shadow:#FF0000 0 0 10px;
}
</style>
