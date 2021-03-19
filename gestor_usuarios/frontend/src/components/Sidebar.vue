<template>
    <nav id="sidebarMenu" class="col-md-3 col-lg-3 d-md-block sidebar collapse">
        <div class="position-sticky pt-3">
            <ul class="nav flex-column">
                <li class="nav-item">
                    <a href="#" class="" @click="get_link('Usuarios')" v-bind:class="[$route.name === 'Usuarios' ? 'nav-link--active': 'nav-link']">Usuarios <i class="fa fa-chevron-right"></i></a>
                </li>
                <li class="nav-item">
                    <a href="#" class="" @click="get_link('Roles')" v-bind:class="[$route.name === 'Roles' ? 'nav-link--active': 'nav-link']">Roles <i class="fa fa-chevron-right"></i></a>
                </li>
                <li class="nav-item">
                    <a href="#" class="" @click="get_link('Unidades')" v-bind:class="[$route.name === 'Unidades' ? 'nav-link--active': 'nav-link']">Unidades <i class="fa fa-chevron-right"></i></a>
                </li>
                <li class="nav-item">
                    <a href="#" class="" @click="get_link('Macroprocesos')" v-bind:class="[$route.name === 'Macroprocesos' ? 'nav-link--active': 'nav-link']">Macroprocesos <i class="fa fa-chevron-right"></i></a>
                </li>
                <li class="nav-item">
                    <a href="#" class="" @click="get_link('Responsabilidades')" v-bind:class="[$route.name === 'Responsabilidades' ? 'nav-link--active': 'nav-link']">Responsabilidades<i class="fa fa-chevron-right"></i></a>
                </li>
                <li class="nav-item">
                    <a href="#" class="" @click="get_link('Etapas')" v-bind:class="[$route.name === 'Etapas' ? 'nav-link--active': 'nav-link']">Etapas<i class="fa fa-chevron-right"></i></a>
                </li>
                <li class="nav-item">
                    <a href="#" class="" @click="get_link('Procesos')" v-bind:class="[$route.name === 'Procesos' ? 'nav-link--active': 'nav-link']">Procesos<i class="fa fa-chevron-right"></i></a>
                </li>
            </ul>
            <hr>
      </div>
    </nav>

</template>

<script>

export default {
  name: 'Menu',
  components: { },
  props: {
    msg: String
  },
  data () {
    return {
    }
  },

  watch: {
  },

  methods: {

    get_link (modulo) {
      modulo = modulo === '' ? 'Usuarios' : modulo
      var route = {
        name: modulo,
        query: { t: (new Date()).getTime() }
      }
      this.$router.push(route)
    }
  },
  mounted () {

  }
}
</script>
