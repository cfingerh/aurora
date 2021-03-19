<template>
  <header class="navbar sticky-top flex-md-nowrap p-0 shadow">
      <a class="navbar-brand col-md-3 col-lg-3 me-0 px-3" href="#">Gestor Auxiliar Aurora</a>
      <button class="navbar-toggler position-absolute d-md-none collapsed" type="button" data-bs-toggle="collapse" data-bs-target="#sidebarMenu" aria-controls="sidebarMenu" aria-expanded="false" aria-label="Toggle navigation">
        <span class="navbar-toggler-icon"></span>
      </button>
      <div class="w-100" type="text" style="text-align:center" v-if="$store.state.direccion">
        <h2>{{$store.state.direccion.empresa__nombre}}: {{$store.state.direccion.nombre}}</h2>
      </div>
      <!-- <input class="form-control form-control-dark w-100" type="text" placeholder="Search" aria-label="Search"> -->
      <ul class="navbar-nav px-3">
        <li class="nav-item text-nowrap">
          <a class="nav-link" href="#" @click="logout()">Salir <i class="fas fa-sign-out-alt"></i></a>
        </li>
      </ul>
    </header>
</template>

<script>
export default {
  name: 'Horizontal',
  components: { },
  props: { },
  data () {
    return { }
  },
  watch: {
    '$store.state.direccion': function () {}
  },
  methods: {
    logout () {
      this.visible = false
      this.$router.push({ name: 'Logout' })
    }
  },
  mounted () { }
}
</script>
