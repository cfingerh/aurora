<template>
  <div class="container">
    <breadcrumb></breadcrumb>

    <div class="card card--white h-auto w-100 mb-3">
      <div class="card-header">
        <div class="d-flex bd-highlight">
          <div class="p-2 mt-2 flex-grow-1 bd-highlight">
            <h4 class="ficha-cliente__header">Procesos</h4>
          </div>
        </div>
      </div>
      <div class="card-body" >
        <a href="#" @click="ejemplo"><i class="fas fa-plus"></i> Cargar Ejemplo</a>
        <br>
        <a href="#" @click="nuevo"><i class="fas fa-plus"></i> Nuevo Proceso </a>

        <div>
            <h3>Responsabilidades</h3>
            <div v-for="responsabilidad in detalle.responsabilidades" v-bind:key="responsabilidad.id">{{responsabilidad.name}}</div>
        </div>

        <div>
            <h3>Tareas</h3>
            <table class="table">
                <tr>
                    <th>Nombre</th>
                    <th>Responsabilidad</th>
                    <th>Etapa</th>
                    <th>Plazo</th>
                    <th>Documento</th>
                    <th>Siguientes</th>
                </tr>

                <tr v-for="tarea in detalle.tareas" v-bind:key="tarea.id">
                    <td>{{tarea.name}}</td>
                    <td>{{tarea.lane_name}}</td>
                    <td>{{tarea.etapa_name}}</td>
                    <td>{{tarea.plazo}}</td>
                    <td>{{tarea.tipodocumento_name}}</td>
                    <td>
                        <div v-for="siguiente in tarea.siguientes" v-bind:key="siguiente.id">{{siguiente.name}}</div>
                    </td>
                </tr>
            </table>
        </div>

        <div class="row">
          <div class="col-12" v-for="proceso in procesos" v-bind:key="proceso.id">
            <div style="border:1px solid black; margin:5px;padding:5px">
              <quick-edit class="quick-edit-same-line" v-model="proceso.nombre" @input="guardar(proceso)"></quick-edit>
              <div style="float:right"><a href="#" @click="eliminar(proceso)"><i class="fas fa-trash" ></i></a>
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
      procesos: [],
      detalle: {}
    }
  },
  methods: {

    get_procesos () {
      var url = '/procesos/api/procesos'
      axios.get(url).then(res => { this.procesos = res.data })
    },

    guardar (rol) {
      var url = `/procesos/api/procesos/${rol.id}/`
      axios.put(url, rol).then(res => { this.get_procesos() })
    },

    eliminar (rol) {
      var self = this
      this.$dialog
        .confirm('Eliminar Rol?')
        .then(function (dialog) {
          var url = `/procesos/api/procesos/${rol.id}/`
          axios.delete(url).then(res => { self.get_procesos() })
          dialog.close()
        })
    },

    nuevo () {
      var url = '/procesos/api/procesos/'
      axios.post(url, { nombre: 'nuevo' }).then(res => { this.get_procesos() })
    },

    ejemplo () {
      var url = '/procesos/api/ejemplo/'
      axios.get(url).then(res => {
        this.detalle = res.data
        this.get_procesos()
      })
    }

  },
  mounted () {
    this.get_procesos()
    this.ejemplo()
  }
}
</script>
