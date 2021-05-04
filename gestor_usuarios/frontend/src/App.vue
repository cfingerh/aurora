<template>
  <div id="app">
  <notifications position="top right"/>
    <horizontal></horizontal>

<div class="container-fluid">
  <div class="row">

    <sidebar v-if="$route.name!='Login'"></sidebar>

    <main class="col-md-9 ms-sm-auto col-lg-9 px-md-4">
        <router-view :key="$route.fullPath"></router-view>
    </main>
  </div>
</div>
  </div>
</template>

<script>

// import MenuBar from '@/components/Menu.vue'
import Horizontal from '@/components/Horizontal.vue'
import Sidebar from '@/components/Sidebar.vue'

export default {
  name: 'Menu',
  props: [],
  components: { Horizontal, Sidebar },
  data () {
    return {
    }
  },
  methods: {
  },
  mounted () {
    // debugger
  }
}
</script>
