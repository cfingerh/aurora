// import axios from 'axios'
// import _ from 'lodash'
import moment from 'moment'

export const utils = {
  created: function () { },
  data () {
    return {
      errorFecha: null,
      isUpdating: false,
      isDownloading: false
    }
  },
  methods: {
    validate_rango_fecha () {
      var diaLimite = null
      if (moment().format('D') * 1 > 6) {
        diaLimite = moment().startOf('month')
      } else {
        diaLimite = moment().startOf('month').subtract(1, 'd').startOf('month')
      }

      var desde = moment(this.$route.query.desde).endOf('month')
      var hasta = moment(this.$route.query.hasta).endOf('month')
      if (desde >= diaLimite || hasta >= diaLimite) {
        this.errorFecha = 'Cartola todavía no disponible para el rango de fecha seleccionado'
        return false
      }
      return true
    },
    get_current_direccion () {
      var self = this
      if (!this.$store.state.direcciones) { return {} }
      return self.$store.state.direcciones.filter(function (direccion) { return direccion.id === self.$route.params.id })[0]
    //   this.$route.params.id
    }

  }
}
