<template>
  <div class="container">
    <breadcrumb></breadcrumb>

    <div class="card card--white h-auto w-100 mb-3">
      <div class="card-header">
        <div class="d-flex bd-highlight">
          <div class="p-2 mt-2 flex-grow-1 bd-highlight">
            <h4 class="ficha-cliente__header">Parámetros</h4>
          </div>
        </div>
      </div>
      <div class="card-body" >
        <a href="#" @click="nuevo"><i class="fas fa-plus"></i> Nuevo </a>
        <div class="row">
          <div class="col-12" v-for="parametro in parametros" v-bind:key="parametro.id">
              <div style="border:1px solid black; margin:5px;padding:5px">
                  <quick-edit class="quick-edit-same-line" v-model="parametro.nombre" @input="guardar(parametro)"></quick-edit>
                  <div style="float:right"><a href="#" @click="eliminar(parametro)"><i class="fas fa-trash" ></i></a></div>
                    <br>
                  String: <quick-edit class="quick-edit-same-line" v-model="parametro.valor_parametro_char" @input="guardar(parametro)"></quick-edit>
                Número: <quick-edit class="quick-edit-same-line" v-model="parametro.valor_parametro_numerico" @input="guardar(parametro)"></quick-edit>
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
      parametros: [],
    }
  },
  methods: {

    get_parametros () {
      var url = '/parametros/api/parametros'
      axios.get(url).then(res => { this.parametros = res.data })
    },

    guardar (rol) {
      var url = `/parametros/api/parametros/${rol.id}/`
      axios.put(url, rol).then(res => { this.get_parametros() })
    },

    eliminar (rol) {
      var self = this
      this.$dialog
        .confirm('Eliminar Rol?')
        .then(function (dialog) {
          var url = `/parametros/api/parametros/${rol.id}/`
          axios.delete(url).then(res => { self.get_parametros() })
          dialog.close()
        })
    },

    nuevo () {
      var url = '/parametros/api/parametros/'
      axios.post(url, { nombre: 'nuevo' }).then(res => { this.get_parametros() })
    }

  },
  mounted () {
    this.get_parametros()
  }
}
</script>
