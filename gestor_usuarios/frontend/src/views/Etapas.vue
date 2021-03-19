<template>
  <div class="container">
    <breadcrumb></breadcrumb>

    <div class="card card--white h-auto w-100 mb-3">
      <div class="card-header">
        <div class="d-flex bd-highlight">
          <div class="p-2 mt-2 flex-grow-1 bd-highlight">
            <h4 class="ficha-cliente__header">Etapas</h4>
          </div>
        </div>
      </div>
      <div class="card-body" >
        <a href="#" @click="nuevo"><i class="fas fa-plus"></i> Nueva etapa </a>
        <div class="row">
          <div class="col-12" v-for="etapa in etapas" v-bind:key="etapa.id">
            <div style="border:1px solid black; margin:5px;padding:5px">
                ({{etapa.id}})
              <quick-edit class="quick-edit-same-line" v-model="etapa.nombre" @input="guardar(etapa)"></quick-edit>
              <div style="float:right"><a href="#" @click="eliminar(etapa)"><i class="fas fa-trash" ></i></a>
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
      etapas: [],
    }
  },
  methods: {

    get_etapas () {
      var url = '/etapas/api/etapas'
      axios.get(url).then(res => { this.etapas = res.data })
    },

    guardar (rol) {
      var url = `/etapas/api/etapas/${rol.id}/`
      axios.put(url, rol).then(res => { this.get_etapas() })
    },

    eliminar (rol) {
      var self = this
      this.$dialog
        .confirm('Eliminar Rol?')
        .then(function (dialog) {
          var url = `/etapas/api/etapas/${rol.id}/`
          axios.delete(url).then(res => { self.get_etapas() })
          dialog.close()
        })
    },

    nuevo () {
      var url = '/etapas/api/etapas/'
      axios.post(url, { nombre: 'nuevo' }).then(res => { this.get_etapas() })
    }

  },
  mounted () {
    this.get_etapas()
  }
}
</script>
