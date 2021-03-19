<template>
  <div class="container">
    <breadcrumb></breadcrumb>

    <div class="card card--white h-auto w-100 mb-3">
      <div class="card-header">
        <div class="d-flex bd-highlight">
          <div class="p-2 mt-2 flex-grow-1 bd-highlight">
            <h4 class="ficha-cliente__header">Macroprocesos</h4>
          </div>
        </div>
      </div>
      <div class="card-body" >
        <a href="#" @click="nuevo"><i class="fas fa-plus"></i> Nuevo Macroproceso </a>
        <div class="row">
          <div class="col-12" v-for="macroproceso in macroprocesos" v-bind:key="macroproceso.id">
            <div style="border:1px solid black; margin:5px;padding:5px">
              <quick-edit class="quick-edit-same-line" v-model="macroproceso.nombre" @input="guardar(macroproceso)"></quick-edit>
              <div style="float:right"><a href="#" @click="eliminar(macroproceso)"><i class="fas fa-trash" ></i></a>
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
import Breadcrumb from '@/components/Breadcrumb.vue'
import QuickEdit from 'vue-quick-edit'

export default {
  name: 'Cartola',
  components: { Breadcrumb, QuickEdit },
  props: {
    msg: String
  },
  data () {
    return {
      macroprocesos: [],
    }
  },
  methods: {

    get_macroprocesos () {
      var url = '/macroprocesos/api/macroprocesos'
      axios.get(url).then(res => { this.macroprocesos = res.data })
    },

    guardar (rol) {
      var url = `/macroprocesos/api/macroprocesos/${rol.id}/`
      axios.put(url, rol).then(res => { this.get_macroprocesos() })
    },

    eliminar (rol) {
      var self = this
      this.$dialog
        .confirm('Eliminar Rol?')
        .then(function (dialog) {
          var url = `/macroprocesos/api/macroprocesos/${rol.id}/`
          axios.delete(url).then(res => { self.get_macroprocesos() })
          dialog.close()
        })
    },

    nuevo () {
      var url = '/macroprocesos/api/macroprocesos/'
      axios.post(url, { nombre: 'nuevo' }).then(res => { this.get_macroprocesos() })
    }

  },
  mounted () {
    this.get_macroprocesos()
  }
}
</script>
