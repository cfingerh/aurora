import Vue from 'vue'
import App from './App.vue'
import Vuex from 'vuex'

import router from './router'
import { BootstrapVue, IconsPlugin } from 'bootstrap-vue'
import '@fortawesome/fontawesome-free/css/all.css'
import '@fortawesome/fontawesome-free/js/all.js'

import Notifications from 'vue-notification'
import VuejsDialog from 'vuejs-dialog'

import 'vuejs-dialog/dist/vuejs-dialog.min.css'
import 'bootstrap'
import 'bootstrap/dist/css/bootstrap.min.css'
import 'bootstrap-vue/dist/bootstrap-vue.css'
import Multiselect from 'vue-multiselect'
// import VueXlsx from 'vue-js-xlsx'
import './app.css'
const moment = require('moment')
require('moment/locale/es')

Vue.use(IconsPlugin)
Vue.use(Vuex)
Vue.config.productionTip = false
Vue.use(BootstrapVue)
Vue.use(require('vue-moment'), {
  moment
})
Vue.use(VuejsDialog, {
  html: true,
  loader: true,
  okText: 'Aceptar',
  cancelText: 'Cancelar',
  animation: 'bounce'
})
// Vue.use(VueXlsx)
Vue.use(Notifications)
Vue.component('multiselect', Multiselect)

var numeral = require('numeral')

Vue.filter('formatNumber', function (value) {
  return numeral(value).format('0,0') // displaying other groupings/separators is possible, look at the docs
})

const store = new Vuex.Store({
  state: {
    direccion: null,
    direcciones: [],
    user: null
  },
  mutations: {
    putUser (state, data) {
      state.user = data
    },
    putDirecciones (state, data) {
      state.direcciones = data
    },
    putDireccion (state, data) {
      state.direccion = data
    }
  }
})

new Vue({
  router,
  store: store,
  render: h => h(App)
}).$mount('#app')
