<template>
  <div class="container">
    <div class="row">
      <div class="col-4">
        <div class="content-login">
          <div class="card">
            <div class="card-header bg--dark-blue">
              <h2 class="card-title">Bienvenido al Gestor de Tablas Auxiliares</h2>
            </div>
            <div class="card-body login">
              <div class="form">
                <div class="form-group">
                  <label>Usuario</label>
                  <input
                    type="text"
                    class="form-control"
                    v-model="loginData.username"
                    placeholder="Usuario"
                  />
                  <small class="form-text text-muted"></small>
                </div>
                <div class="form-group">
                  <label>Clave</label>
                  <input
                    type="password"
                    class="form-control"
                    v-model="loginData.password"
                    placeholder="Clave"
                  />
                  <small class="form-text text-muted"></small>
                </div>
                <br />
                <div
                  v-show="loginError"
                  class="alert alert-warning"
                  role="alert"
                >Credenciales incorrectas</div>
                <button type="button" class="btn btn-primary" @click="loginFuncionario">Ingresar</button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import axios from 'axios'

export default {
  name: 'Home',
  components: {},
  data () {
    return {
      loginError: false,
      loginData: { username: null, password: null }
    }
  },
  mounted () {
    localStorage.removeItem('jwt.access')
    localStorage.removeItem('jwt.refresh')
  },

  methods: {
    loginFuncionario (e) {
      var self = this
      e.preventDefault()
      var url = '/api/token/'
      self.loginError = false
      axios({
        method: 'post',
        url: url,
        data: {
          username: self.loginData.username,
          password: self.loginData.password
        }
      })
        .then(function (response) {
          localStorage.setItem('jwt.access', response.data.access)
          localStorage.setItem('jwt.refresh', response.data.refresh)
          self.$router.push('cartola/')
          location.reload()
        })
        .catch(function (response) {
          self.error = response
          self.loginError = true
        })
    }
  }
}
</script>
