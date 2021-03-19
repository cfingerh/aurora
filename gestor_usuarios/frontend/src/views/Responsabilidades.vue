<template>
  <div class="container">
    <breadcrumb></breadcrumb>

    <div class="card card--white h-auto w-100 mb-3">
      <div class="card-header">
        <div class="d-flex bd-highlight">
          <div class="p-2 mt-2 flex-grow-1 bd-highlight">
            <h4 class="ficha-cliente__header">Responsabilidades (Swim Lanes</h4>
          </div>
        </div>
      </div>
      <div class="card-body" >
        <a href="#" @click="nuevo"><i class="fas fa-plus"></i> Nueva Responsabilidad </a>
        <div class="row">
          <div class="col-12" v-for="responsabilidad in responsabilidades" v-bind:key="responsabilidad.id">
            <div style="border:1px solid black; margin:5px;padding:5px">
              <quick-edit class="quick-edit-same-line" v-model="responsabilidad.nombre" @input="guardar(responsabilidad)"></quick-edit>
              <div style="float:right"><a href="#" @click="eliminar(responsabilidad)"><i class="fas fa-trash" ></i></a>
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
      responsabilidades: [],
    }
  },
  methods: {

    get_responsabilidades () {
      var url = '/responsabilidades/api/responsabilidades'
      axios.get(url).then(res => { this.responsabilidades = res.data })
    },

    guardar (rol) {
      var url = `/responsabilidades/api/responsabilidades/${rol.id}/`
      axios.put(url, rol).then(res => { this.get_responsabilidades() })
    },

    eliminar (rol) {
      var self = this
      this.$dialog
        .confirm('Eliminar Rol?')
        .then(function (dialog) {
          var url = `/responsabilidades/api/responsabilidades/${rol.id}/`
          axios.delete(url).then(res => { self.get_responsabilidades() })
          dialog.close()
        })
    },

    nuevo () {
      var url = '/responsabilidades/api/responsabilidades/'
      axios.post(url, { nombre: 'nuevo' }).then(res => { this.get_responsabilidades() })
    }

  },
  mounted () {
    this.get_responsabilidades()
  }
}
</script>
