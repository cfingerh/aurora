<template>
  <div class="container">
    <breadcrumb></breadcrumb>

    <div class="card card--white h-auto w-100 mb-3">
      <div class="card-header">
        <div class="d-flex bd-highlight">
          <div class="p-2 mt-2 flex-grow-1 bd-highlight">
            <h4 class="ficha-cliente__header">Unidades</h4>
          </div>
        </div>
      </div>
      <div class="card-body" >
        <a href="#" @click="nuevo"><i class="fas fa-plus"></i> Nueva Unidad </a>
        <div class="row">
          <div class="col-12" v-for="unidad in unidades" v-bind:key="unidad.id">
            <div style="border:1px solid black; margin:5px;padding:5px">
              <quick-edit class="quick-edit-same-line" v-model="unidad.nombre" @input="guardar(unidad)"></quick-edit>
              <div style="float:right"><a href="#" @click="eliminar(unidad)"><i class="fas fa-trash" ></i></a>
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
      unidades: [],
    }
  },
  methods: {

    get_unidades () {
      var url = '/unidades/api/unidades'
      axios.get(url).then(res => { this.unidades = res.data })
    },

    guardar (rol) {
      var url = `/unidades/api/unidades/${rol.id}/`
      axios.put(url, rol).then(res => { this.get_unidades() })
    },

    eliminar (rol) {
      var self = this
      this.$dialog
        .confirm('Eliminar Rol?')
        .then(function (dialog) {
          var url = `/unidades/api/unidades/${rol.id}/`
          axios.delete(url).then(res => { self.get_unidades() })
          dialog.close()
        })
    },

    nuevo () {
      var url = '/unidades/api/unidades/'
      axios.post(url, { nombre: 'nuevo' }).then(res => { this.get_unidades() })
    }

  },
  mounted () {
    this.get_unidades()
  }
}
</script>
