<div>
    <b-navbar toggleable="lg" type="dark" variant="info">
      <!-- <b-navbar-brand href="#">NavBar</b-navbar-brand> -->
      <b-navbar-toggle target="nav-collapse"></b-navbar-toggle>

      <b-collapse id="nav-collapse" is-nav>
        <b-navbar-nav>
          <b-nav-item  v-on:click="get_link('Cartola')">Cartola</b-nav-item>
          <b-nav-item  v-on:click="get_link('Sinader')">Sinader</b-nav-item>
          <b-nav-item  v-on:click="get_link('Documentos')">Documentos</b-nav-item>
          <b-nav-item  v-on:click="get_link('Rga')">RGA</b-nav-item>
        </b-navbar-nav>
        <b-navbar-nav class="ml-auto">
          <b-nav-form>
            <date-range-picker 
              v-model="dateRange"
              ref="picker"
              :autoApply="true"
              :timePicker="false"
              :locale-data="{ 
                firstDay: 1, 
                daysOfWeek: ['Dom', 'Lun', 'Mar', 'Mie', 'Jue', 'Vie', 'Sab'],
                format: 'DD-MM-YYYY' }"
              >
              <template
                v-slot:input="picker"
                style="min-width: 350px;"
              >{{ picker.startDate | moment("DD MMM YYYY")}} al {{ picker.endDate | moment("DD MMM YYYY")}}</template>
            </date-range-picker>
                
          </b-nav-form>
          <b-nav-form>
            <b-form-select
              v-if="direcciones.length>0"
              v-model="selected"
              :options="direcciones"
              class="mb-3"
              value-field="id"
              text-field="nombre"
              @change="refreshUrl"
            ></b-form-select>
            <!-- <b-form-input size="sm" class="mr-sm-2" placeholder="Search"></b-form-input> -->
            <!-- <b-button size="sm" class="my-2 my-sm-0" type="submit">Search</b-button> -->
          </b-nav-form>
          <b-nav-item-dropdown right>
            <template v-slot:button-content>
              <em>Usuario</em>
            </template>
            <b-dropdown-item href="#">Perfil</b-dropdown-item>
            <b-dropdown-item href="#">Salir</b-dropdown-item>
          </b-nav-item-dropdown>
        </b-navbar-nav>
      </b-collapse>
    </b-navbar>
  </div>
  