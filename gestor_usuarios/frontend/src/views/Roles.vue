<template>
  <div class="container">
    <breadcrumb></breadcrumb>

    <div class="card card--white h-auto w-100 mb-3">
      <div class="card-header">
        <div class="d-flex bd-highlight">
          <div class="p-2 mt-2 flex-grow-1 bd-highlight">
            <h4 class="ficha-cliente__header">Roles</h4>
          </div>
        </div>
      </div>
      <div class="card-body" >
        <a href="#" @click="nuevo"><i class="fas fa-plus"></i> Nuevo Rol </a>
        <div class="row">
          <div class="col-12" v-for="rol in roles" v-bind:key="rol.id">
            <div style="border:1px solid black; margin:5px;padding:5px">
              <quick-edit class="quick-edit-same-line" v-model="rol.nombre" @input="guardar(rol)"></quick-edit>
              <div style="float:right"><a href="#" @click="eliminar(rol)"><i class="fas fa-trash" ></i></a>
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
      roles: [],
    }
  },
  watch: {
    // nuevo: {
    //   handler: function (val) { console.log('changed') },
    //   deep: true
    // }
  },
  methods: {

    get_roles () {
      var url = '/roles/api/roles'
      axios.get(url).then(res => {
        this.roles = res.data
      })
    },

    guardar (rol) {
      var url = `/roles/api/roles/${rol.id}/`
      axios.put(url, rol).then(res => { this.get_roles() })
    },

    eliminar (rol) {
      var self = this
      this.$dialog
        .confirm('Eliminar Rol?')
        .then(function (dialog) {
          var url = `/roles/api/roles/${rol.id}/`
          axios.delete(url).then(res => { self.get_roles() })
          dialog.close()
        })
    },

    nuevo () {
      var url = '/roles/api/roles/'
      axios.post(url, { nombre: 'nuevo' }).then(res => { this.get_roles() })
    }

  },
  mounted () {
    this.get_roles()
  }
}
</script>
