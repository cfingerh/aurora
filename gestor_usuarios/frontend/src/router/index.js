import Vue from 'vue'
import VueRouter from 'vue-router'
import Login from '../views/Login.vue'
import Usuarios from '../views/Usuarios.vue'
import Roles from '../views/Roles.vue'
import Unidades from '../views/Unidades.vue'
import Macroprocesos from '../views/Macroprocesos.vue'
import Responsabilidades from '../views/Responsabilidades.vue'
import Procesos from '../views/Procesos.vue'
import Etapas from '../views/Etapas.vue'

import axios from 'axios'

Vue.use(VueRouter)

const routes = [
  { path: '/', redirect: '/usuarios' },
  { path: '/login', name: 'Login', component: Login, meta: { noAuth: true } },
  { path: '/login?logout', name: 'Logout', meta: { noAuth: false } },
  { path: '/usuarios/', name: 'Usuarios', component: Usuarios, meta: { noAuth: true } },
  { path: '/roles/', name: 'Roles', component: Roles, meta: { noAuth: true } },
  { path: '/unidades/', name: 'Unidades', component: Unidades, meta: { noAuth: true } },
  { path: '/macroprocesos/', name: 'Macroprocesos', component: Macroprocesos, meta: { noAuth: true } },
  { path: '/responsabilidades/', name: 'Responsabilidades', component: Responsabilidades, meta: { noAuth: true } },
  { path: '/procesos/', name: 'Procesos', component: Procesos, meta: { noAuth: true } },
  { path: '/etapas/', name: 'Etapas', component: Etapas, meta: { noAuth: true } }

]

const router = new VueRouter({
  mode: 'history',
  base: process.env.BASE_URL,
  routes
})

router.beforeEach(function (to, from, next) {
  if (to.fullPath === '/login?logout') {
    localStorage.removeItem('jwt.access')
    localStorage.removeItem('jwt.refresh')
    next({ path: '/login' })
    return
  }
  console.log(to.fullPath)
  if (!to.meta.noAuth) {
    console.log(to.fullPath)
    if (localStorage.getItem('jwt.access') === null) {
      next({ path: '/login', params: { nextUrl: to.fullPath } })
      return
    }
  }
  next()
})

axios.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('jwt.access')
    if (config.url.search('http') !== 0) {
      config.url = process.env.VUE_APP_BASEURL + config.url
    }
    if (token) {
      config.headers.Authorization = `Bearer ${token}`
    }

    return config
  },

  (error) => {
    return Promise.reject(error)
  }
)

axios.interceptors.response.use((response) => {
  return response
}, function (error) {
  const originalRequest = error.config

  if (error.response && error.response.status === 401 && error.response.data && error.response.data.detail === 'Authentication credentials were not provided.') {
    localStorage.removeItem('jwt.access')
    router.push('/login')
    return Promise.reject(error)
  }

  if (error.response.status === 401 && error.response.data && error.response.data.code === 'token_not_valid') {
    // si el url es el refresh, signifia que ya es el segundo request una vez que el primero no fue existos o por tanto debe devolver el error
    if (error.config.url.search('/api/token/refresh/') >= 0) {
      localStorage.removeItem('jwt.access')
      router.push('/login')
      return Promise.reject(error)
    }

    const refreshToken = localStorage.getItem('jwt.refresh')
    return axios.post(process.env.VUE_APP_BASEURL + '/api/token/refresh/', { refresh: refreshToken })
      .then(function (res) {
        if (res.status === 200) {
          localStorage.setItem('jwt.access', res.data.access)
          return axios(originalRequest)
        }
      }).catch(function () {
        localStorage.removeItem('jwt.access')
        localStorage.removeItem('jwt.refresh')

        router.push({
          name: 'login',
          query: {
            t: new Date().getTime()
          }
        })
      })
  }

  return Promise.reject(error)

  // if (error.response.status === 401 && originalRequest.url === 'http://13.232.130.60:8081/v1/auth/token) {
  //   router.push('/login')
  //   return Promise.reject(error)
  // }
})

export default router
