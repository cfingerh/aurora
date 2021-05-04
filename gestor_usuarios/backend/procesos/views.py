from django.shortcuts import render
from xml.dom import minidom

from datetime import date, datetime
from base.models import Proceso, Tarea, ResponsabilidadTarea, TareasRoles, TipoDeDocumento, Responsabilidad, Etapa, Roles, ResponsabilidadTarea, InstanciasDeProcesos, InstanciasDeTareas, UsuariosAsignadosATareas, SeguimientoIntanciaProcesos, ReferenciasDeTarea, Permiso
from base.models import Macroproceso
from django.http import JsonResponse


def ejemplo(request):
    7 / 0
    bpmn = Bpmn()

    resp = {
        'responsabilidades': [el.__dict__ for el in bpmn.lanes],
        'tareas': [el.__dict__ for el in bpmn.tasks],
        'tiposdocumento': [el.__dict__ for el in bpmn.dataobjects]
    }
    instanciaProceso = Proceso.iniciar(nombre='proceso_prueba')

    return JsonResponse(resp)


def get_dicts_from_array(els):
    return [el.__dict__ for el in els]


class Bpmn():

    def __init__(self):
        self.nombre = 'proceso_prueba'
        self.macroproceso_id = 11
        self.unidad_id = 11
        self.dias_habiles_max_duracion = 50

        self.xml_file = "ejemplo.bpmn"
        self.mydoc = minidom.parse('ejemplo.bpmn')

        SeguimientoIntanciaProcesos.objects.all().delete()
        UsuariosAsignadosATareas.objects.all().delete()
        InstanciasDeTareas.objects.all().delete()
        InstanciasDeProcesos.objects.all().delete()
        ResponsabilidadTarea.objects.all().delete()
        ReferenciasDeTarea.objects.all().update(tarea_siguiente=None)
        ReferenciasDeTarea.objects.all().delete()
        TareasRoles.objects.all().delete()
        Tarea.objects.all().delete()
        Proceso.objects.all().delete()

        self.get_tasks()
        self.get_start()
        self.get_lanes()
        self.get_dataobjects()
        self.asignar_lane_a_tasks()
        self.guardar_proceso()

        self.guardar_responsabilidades()
        self.guardar_tiposdocumento()
        self.guardar_tareas()
        self.guardar_referenciastareas()

        return

    def get_start(self):
        """
        Busca elemento de inicio (circulo) y guardar .start_id el id
        Busca la primera tarea y la guarda en .first_task
        """
        if len(self.mydoc.getElementsByTagName('bpmn:startEvent')) == 0:
            self.add_error("No hay elemento de Inicio")

        self.start_id = self.mydoc.getElementsByTagName('bpmn:startEvent')[0].getAttribute("id")
        # aaa = self.get_next_tasks('Activity_0paqco8')

    def get_next_tasks(self, id, tasks=[]):
        """Recibe un ID y devuelve los tasks siguientesself.
        Si es un agatway, devuelve el gateway y los siguientes
        Se basa solo en el XML"""
        for t in self.mydoc.getElementsByTagName('bpmn:startEvent'):
            if t.getAttribute("id") == id:
                task = t
                continue

        for t in self.mydoc.getElementsByTagName('bpmn:task'):
            if t.getAttribute("id") == id:
                task = t
                continue

        for t in self.mydoc.getElementsByTagName('bpmn:exclusiveGateway'):
            if t.getAttribute("id") == id:
                task = t
                continue

        for flow in task.getElementsByTagName('bpmn:outgoing'):
            flow_id = flow.childNodes[0].nodeValue
            for t in self.mydoc.getElementsByTagName('bpmn:incoming'):
                if t.childNodes[0].nodeValue == flow_id:
                    if t.parentNode.tagName.split(":")[1] == 'exclusiveGateway':
                        tasks = self.get_next_tasks(t.parentNode.getAttribute('id'), tasks=tasks)
                    tasks.append({
                        'tag': t.parentNode.tagName.split(":")[1],
                        'name': t.parentNode.getAttribute('name'),
                        'id': t.parentNode.getAttribute('id')
                    })
        return tasks

    def get_previous_tasks(self, id, tasks=[]):
        """
        Recibe un ID y devuelve los tasks anteriores: por ahora siempre debiese ser solo uno (o 0 para el inicial).
        Si es un agatway, devuelve el gateway y el anterior
        Se basa solo en el XML"""
        for t in self.mydoc.getElementsByTagName('bpmn:startEvent'):
            if t.getAttribute("id") == id:
                task = t
                continue

        for t in self.mydoc.getElementsByTagName('bpmn:task'):
            if t.getAttribute("id") == id:
                task = t
                continue

        for t in self.mydoc.getElementsByTagName('bpmn:exclusiveGateway'):
            if t.getAttribute("id") == id:
                task = t
                continue

        for flow in task.getElementsByTagName('bpmn:incoming'):
            flow_id = flow.childNodes[0].nodeValue
            for t in self.mydoc.getElementsByTagName('bpmn:outgoing'):
                if t.childNodes[0].nodeValue == flow_id:
                    if t.parentNode.tagName.split(":")[1] == 'exclusiveGateway':
                        tasks = self.get_previous_tasks(t.parentNode.getAttribute('id'), tasks=tasks)
                    tasks.append({
                        'tag': t.parentNode.tagName.split(":")[1],
                        'name': t.parentNode.getAttribute('name'),
                        'id': t.parentNode.getAttribute('id')
                    })
        return tasks

    def get_tasks(self):
        if not hasattr(self, 'tasks'):
            self.tasks = self.mydoc.getElementsByTagName('bpmn:task')
            for task in self.tasks:
                task.name = task.getAttribute('name')
                task.id = task.getAttribute('id')

                # Next
                task.siguientes = self.get_next_tasks(task.id, tasks=[])
                task.anteriores = self.get_previous_tasks(task.id, tasks=[])
                task.es_inicio = len(task.anteriores) == 0
                task.es_fin = len(task.siguientes) == 0

                task.tipo = 'OR' if len(task.siguientes) > 1 else None

                # Documentos
                documentos = [t.childNodes[0].nodeValue for t in task.getElementsByTagName('bpmn:targetRef')]
                if len(documentos) > 0:
                    task.tipodocumento_name = [t.getAttribute('name') for t in self.mydoc.getElementsByTagName('bpmn:dataObjectReference') if t.getAttribute('id') == documentos[0]][0]

                # Plazo
                plazos = [t.getAttribute('value') for t in task.getElementsByTagName('camunda:property') if t.getAttribute('name') == 'plazo']
                if len(plazos) > 0:
                    task.plazo = plazos[0]
                else:
                    self.add_error("Elemento '{}' no tiene definido plazo".format(task.name))

                # buscar etapa
                etapas_value = [t.getAttribute('value') for t in task.getElementsByTagName('camunda:property') if t.getAttribute('name') == 'etapa']
                if len(etapas_value) > 0:
                    etapa_value = etapas_value[0]
                    etapa = Etapa.objects.filter(pk=etapa_value).first()
                    if etapa:
                        task.etapa_id = etapa.id
                        task.etapa_name = etapa.nombre
                    else:
                        self.add_error("Elemento '{}' tiene asignada etapa {} que no existe en las tablas Auxiliares".format(task.name, etapa_value))
                else:
                    self.add_error("Elemento '{}' no tiene asignada etapa".format(task.name))

        return self.tasks

    def get_lanes(self):
        if not hasattr(self, 'lanes'):
            self.lanes = self.mydoc.getElementsByTagName('bpmn:lane')
            for lane in self.lanes:
                lane.name = lane.getAttribute('name')
                lane.id = lane.getAttribute('id')
        return self.lanes

    def get_dataobjects(self):
        if not hasattr(self, 'dataobjects'):
            self.dataobjects = self.mydoc.getElementsByTagName('bpmn:dataObjectReference')
            for dataobject in self.dataobjects:
                dataobject.name = dataobject.getAttribute('name')
                dataobject.id = dataobject.getAttribute('id')
        return self.dataobjects

    def asignar_lane_a_tasks(self):
        for task in self.get_tasks():
            self.asignar_lane_a_task(task)

    def guardar_proceso(self):

        defaults = {'macroproceso_id': self.macroproceso_id,
                    'dias_habiles_max_duracion': self.dias_habiles_max_duracion,
                    'descripcion': self.nombre,
                    'vigente': True,
                    'confidencial': False,
                    'unidad_id': self.unidad_id,
                    'codigo_proceso': 'CFFM--01'

                    }
        self.proceso = Proceso.objects.update_or_create(nombre=self.nombre, defaults=defaults)[0]
        Proceso.objects.filter(codigo_proceso=self.proceso.codigo_proceso).exclude(pk=self.proceso.id).update(vigente=False)

    def guardar_referenciastareas(self):
        orden = 0
        for task in self.get_tasks():
            tarea = Tarea.objects.get(proceso=self.proceso, id_diagrama=task.id)
            ReferenciasDeTarea.objects.filter(tarea=tarea).delete()
            for siguiente in task.siguientes:
                if siguiente.get("tag") != 'task':
                    continue
                tarea_siguiente = Tarea.objects.get(proceso=self.proceso, id_diagrama=siguiente.get("id"))
                ref = ReferenciasDeTarea(tarea=tarea, tarea_siguiente=tarea_siguiente)
                ref.save()

    def guardar_tareas(self):
        orden = 0
        for task in self.get_tasks():
            orden += 1
            defaults = {'dias_habiles_max_duracion': task.plazo or 1,
                        'nombre': task.name,
                        'obligatoria': True,
                        'orden': orden,
                        'puede_visar_documentos': True,
                        'puede_aplicar_fea': False,
                        'vigente': True,
                        'solo_informar': False,
                        'asigna_num_doc': False,
                        'esperar_resp': False,
                        'dias_reseteo': 0,
                        'tipo_reseteo': None,
                        'es_ultima_tarea': task.es_fin,
                        'tipo_de_bifurcacion': task.tipo,
                        'conforma_expediente': False,
                        'distribuye': False,
                        'numeracion_auto': False,
                        'etapa_id': task.etapa_id}
            tarea = Tarea.objects.update_or_create(
                proceso=self.proceso,
                id_diagrama=task.id,
                defaults=defaults)[0]

            ResponsabilidadTarea.objects.update_or_create(
                tarea_id=tarea.id,
                defaults={'responsabilidad_id': Responsabilidad.objects.get(nombre=task.lane_name).id})

    def guardar_tiposdocumento(self):
        for dataobject in self.get_dataobjects():
            TipoDeDocumento.objects.get_or_create(nombre=dataobject.name)

    def guardar_responsabilidades(self):
        for lane in self.get_lanes():
            responsabilidad = Responsabilidad.objects.get_or_create(nombre=lane.name)[0]
            responsabilidad.save()

    def asignar_lane_a_task(self, task):
        # en teoría se podría hacer también iterando por tasks
        for lane in self.get_lanes():
            for element in lane.getElementsByTagName("bpmn:flowNodeRef"):
                lane_id = element.childNodes[0].nodeValue

                for task in self.tasks:
                    if task.getAttribute('id') == lane_id:
                        task.lane = lane_id
                        task.lane_name = lane.getAttribute('name')
