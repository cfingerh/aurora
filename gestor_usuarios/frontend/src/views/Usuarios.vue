<template>
  <div class="container">
    <breadcrumb></breadcrumb>

    <div class="card card--white h-auto w-100 mb-3">
      <div class="card-header">
        <div class="d-flex bd-highlight">
          <div class="p-2 mt-2 flex-grow-1 bd-highlight">
            <h4 class="ficha-cliente__header">Usuarios</h4>
          </div>
        </div>
      </div>
      <div class="card-body" >
        <a href="#" @click="nuevo_usuario"><i class="fas fa-plus"></i> Nuevo Usuario </a>
        <div class="row">
          <div class="col-6" v-for="usuario in usuarios" v-bind:key="usuario.id_usuario">
            <div style="border:1px solid black; margin:5px;padding:5px">
              <h2>
                <quick-edit class="quick-edit-same-line" v-model="usuario.id_usuario_para_modificar" @input="guardar_usuario(usuario)"></quick-edit>
              </h2>

              <label>Nombre</label>
              <quick-edit class="quick-edit-same-line" v-model="usuario.nombre_completo" @input="guardar_usuario(usuario)"></quick-edit>
              <br>
              <label>RUT</label><quick-edit class="quick-edit-same-line" v-model="usuario.rut" @input="guardar_usuario(usuario)"></quick-edit>
              <br>
              <label>Fuera Oficina</label><quick-edit type="boolean" class="quick-edit-same-line" v-model="usuario.fuera_de_oficina" @input="guardar_usuario(usuario)"></quick-edit>
              <table class="table table--secondary">
                <thead>
                  <tr>
                    <th>Rol</th>
                    <th>Unidad</th>
                    <th>Activo</th>
                    <th>
                      <a href="#" @click="nuevo_rol(usuario)"><i class="fas fa-plus"></i></a>
                    </th>
                  </tr>
                </thead>
                <tbody>
                  <tr v-for="rol in usuario.roles" v-bind:key="rol.id">
                    <td><quick-edit type="select" class="quick-edit-same-line" :options="roles" v-model="rol.rol_id" @input="guardar_rol(rol)"></quick-edit></td>
                    <td><quick-edit type="select" class="quick-edit-same-line" :options="unidades" v-model="rol.unidad_id" @input="guardar_rol(rol)"></quick-edit></td>
                    <td><quick-edit type="boolean" class="quick-edit-same-line" v-model="rol.activo" @input="guardar_rol(rol)"></quick-edit></td>
                    <td><a href="#" @click="eliminar_rol(rol)"><i class="fas fa-trash"></i></a></td>
                  </tr>
                </tbody>
              </table>
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
      usuarios: [],
      roles: [],
      unidades: [],
      accion: null,
      nuevoObjeto: { activo: true, fuera_de_oficina: false },
    }
  },
  watch: {
    // nuevo: {
    //   handler: function (val) { console.log('changed') },
    //   deep: true
    // }
  },
  methods: {

    get_usuarios () {
      var url = '/usuarios/api/usuarios'
      axios.get(url).then(res => { this.usuarios = res.data })
    },

    get_roles () {
      var url = '/usuarios/api/roles'
      axios.get(url).then(res => {
        res.data.forEach(item => {
          item.value = item.id
          item.text = item.nombre
        })
        this.roles = res.data
      })
    },

    get_unidades () {
      var url = '/usuarios/api/unidades'
      axios.get(url).then(res => {
        res.data.forEach(item => {
          item.value = item.id
          item.text = item.nombre
        })
        this.unidades = res.data
      })
    },

    nuevo_usuario () {
      this.$dialog
        .prompt({ title: 'Nombre de Usuario', }, {
          promptHelp: ''
        })
        .then(dialog => {
          var url = '/usuarios/api/usuarios/'
          var usuario = { id_usuario: dialog.data }
          axios.post(url, usuario).then(res => { this.get_usuarios() })
          dialog.close()
        })
    },

    guardar_usuario (usuario) {
      var url = `/usuarios/api/usuarios/${usuario.id_usuario}/`
      axios.put(url, usuario).then(res => { this.get_usuarios() })
    },

    guardar_rol (rol) {
      var url = `/usuarios/api/rolesunidades/${rol.id}/`
      axios.put(url, rol).then(res => { this.get_usuarios() })
    },

    eliminar_rol (rol) {
      this.$dialog
        .confirm('Eliminar Rol?')
        .then(function (dialog) {
          var url = `/usuarios/api/rolesunidades/${rol.id}/`
          axios.delete(url).then(res => { this.get_usuarios() })
          dialog.close()
        })
    },

    nuevo_rol (usuario) {
      var url = '/usuarios/api/rolesunidades/'
      axios.post(url, usuario).then(res => { this.get_usuarios() })
    }

  },
  mounted () {
    this.get_usuarios()
    this.get_roles()
    this.get_unidades()
  }
}
</script>
