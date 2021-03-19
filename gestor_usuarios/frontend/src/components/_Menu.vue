<template>
   <div>
    <b-sidebar id="sidebar-right" title="Menu"  left shadow v-model="visible" no-header :no-close-on-route-change="true">
      <div class="px-3 py-2">

      <div>
        <b-list-group>
          <a href="#" class="list-group-item list-group-item-action" @click="get_link('Cartola')">Cartola</a>
          <a href="#" class="list-group-item list-group-item-action" @click="get_link('Sinader')">Sinader</a>
          <a href="#" class="list-group-item list-group-item-action" @click="get_link('Documentos')">Documentos</a>
          <a href="#" class="list-group-item list-group-item-action" @click="get_link('Ecoequivalencia')">Ecoequivalencia</a>
          <!-- <a href="#" class="list-group-item list-group-item-action" @click="get_link('Rga')">RGA</a> -->
        </b-list-group>
      </div>
      <label>Desde</label>
      <b-form-datepicker v-model="desde" @input="change_form" class="mb-2"></b-form-datepicker>
      <label>Hasta</label>
      <b-form-datepicker v-model="hasta" @input="change_form" class="mb-2" :max="max"></b-form-datepicker>

      <div>
        <b-form-select v-model="selected_direccion" @input="change_form" :options="direcciones" text-field="nombre" value-field="id"></b-form-select>
      </div>
    </div>

    <template v-slot:footer="{}">
       <div class="d-flex bg-dark text-light align-items-center px-3 py-2">
        <strong class="mr-auto" v-if="user">{{user.first_name}}</strong>
        <b-button size="sm" @click="logout">Cerrar</b-button>
       </div>
      </template>
    </b-sidebar>
  </div>

</template>

<script>
import axios from 'axios'

export default {
  name: 'Menu',
  components: { },
  props: {
    msg: String
  },
  data () {
    return {
      direcciones: [],
      visible: this.$route.name !== 'Login',
      selected_direccion: null,
      desde: null,
      hasta: null,
      user: null,
      max: this.$moment().subtract(1, 'months').endOf('month').format('YYYY-MM-DD')
    }
  },

  watch: {
    // whenever question changes, this function will run
    dateRange: {
      deep: true,
      handler () {
        this.refreshUrl()
      }
    }
  },
  methods: {
    getUser () {
      var self = this
      axios.get('/users/info').then(function (res) {
        self.$store.commit('putUser', res.data)
        self.user = res.data
      })
    },
    logout () {
      this.visible = false
      this.$router.push({ name: 'Logout' })
    },
    search () {
      var self = this
      axios.get('/base/direcciones/').then(function (res) {
        self.direcciones = res.data
        self.$store.commit('putDirecciones', res.data)
        if (!self.$route.params.id) {
          self.selected_direccion = self.direcciones[0].id
          self.change_form()
        }
        self.selected_direccion = self.$route.params.id
      })
    },
    change_form () {
      this.get_link(this.$route.name)
    },
    get_link (modulo) {
      modulo = modulo === '' ? 'Cartola' : modulo
      var self = this
      this.$router.push({
        name: modulo,
        params: { id: this.selected_direccion },
        query: {
          desde: self.desde,
          hasta: self.hasta,
          t: (new Date()).getTime()
        }
      })
    }
  },
  mounted () {
    this.getUser()
    this.search()
    if (this.$route.params.id) {
      this.selected = this.$route.params.id
    }
    if (this.$route.query.desde) {
      this.desde = this.$moment(this.$route.query.desde).format('YYYY-MM-DD')
    } else {
      this.desde = this.$moment().subtract(1, 'months').startOf('month').format('YYYY-MM-DD')
    }
    if (this.$route.query.hasta) {
      this.hasta = this.$moment(this.$route.query.hasta).format('YYYY-MM-DD')
    } else {
      this.hasta = this.$moment().subtract(1, 'months').endOf('month').format('YYYY-MM-DD')
    }
    // if (this.$route.query.hasta) {
    //   this.dateRange.endDate = new Date(this.$route.query.hasta)
    // }
  }
}
</script>
