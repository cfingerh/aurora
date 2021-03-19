from django.shortcuts import render
from xml.dom import minidom

import ipdb
from base.models import Proceso, Tarea, TipoDeDocumento, Responsabilidad, Etapa
from base.models import Macroproceso
from django.http import JsonResponse


def ejemplo(request):
    bpmn = Bpmn()

    # import ipdb
    # ipdb.set_trace()
    resp = {
        'responsabilidades': [el.__dict__ for el in bpmn.lanes],
        'tareas': [el.__dict__ for el in bpmn.tasks],
        'tiposdocumento': [el.__dict__ for el in bpmn.dataobjects]
    }
    return JsonResponse(resp)


def get_dicts_from_array(els):
    return [el.__dict__ for el in els]


class Bpmn():

    def __init__(self):
        self.nombre = 'proceso_prueba'
        self.macroproceso_id = 11
        self.dias_habiles_max_duracion = 50

        self.xml_file = "ejemplo.bpmn"
        self.mydoc = minidom.parse('ejemplo.bpmn')
        self.get_tasks()
        self.get_start()
        self.get_lanes()
        self.get_dataobjects()
        self.asignar_lane_a_tasks()
        self.guardar_proceso()
        self.guardar_tareas()
        self.guardar_tiposdocumento()
        self.guardar_responsabilidades()

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

    def get_tasks(self):
        if not hasattr(self, 'tasks'):
            self.tasks = self.mydoc.getElementsByTagName('bpmn:task')
            for task in self.tasks:
                task.name = task.getAttribute('name')
                task.id = task.getAttribute('id')

                # Next
                # if task.id == 'Activity_0paqco8':
                task.siguientes = self.get_next_tasks(task.id, tasks=[])

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

    # def get_tag_by_id(self, id, parent=None):
    #     parent = parent or self.mydoc
    #     for cn in parent.childNodes:
    #         try:
    #             cn.getAttribute('id')
    #         except:
    #             continue

    #         if cn.getAttribute('id') == id:
    #             return cn
    #         resp = self.get_tag_by_id(id, parent=cn)
    #         if resp:
    #             return resp

    def guardar_proceso(self):

        defaults = {'macroproceso_id': self.macroproceso_id,
                    'dias_habiles_max_duracion': self.dias_habiles_max_duracion,
                    }

        self.proceso = Proceso.objects.update_or_create(nombre=self.nombre, defaults=defaults)[0]

    def guardar_tareas(self):
        orden = 0
        for task in self.get_tasks():
            orden += 1
            defaults = {'dias_habiles_max_duracion': task.plazo or 1,
                        'orden': orden,
                        'nombre': task.name,
                        'etapa_id': task.etapa_id}
            Tarea.objects.update_or_create(
                proceso=self.proceso,
                id_diagrama=task.id,
                defaults=defaults)

    def guardar_tiposdocumento(self):
        for dataobject in self.get_dataobjects():
            TipoDeDocumento.objects.get_or_create(nombre=dataobject.name)

    def guardar_responsabilidades(self):
        for lane in self.get_lanes():
            Responsabilidad.objects.get_or_create(nombre=lane.name)

    def asignar_lane_a_task(self, task):
        # en teoría se podría hacer también iterando por tasks
        for lane in self.get_lanes():
            for element in lane.getElementsByTagName("bpmn:flowNodeRef"):
                lane_id = element.childNodes[0].nodeValue

                for task in self.tasks:
                    if task.getAttribute('id') == lane_id:
                        task.lane = lane_id
                        task.lane_name = lane.getAttribute('name')
