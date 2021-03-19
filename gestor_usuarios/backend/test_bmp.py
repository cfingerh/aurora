from xml.dom import minidom
from load import *

from base.models import Proceso, Tarea, TipoDeDocumento, Responsabilidad

from base.models import Macroproceso

import ipdb


class Bpmn():

    def __init__(self):
        self.nombre = 'proceso_prueba'
        self.macroproceso_id = 11
        self.dias_habiles_max_duracion = 50

        self.xml_file = "ejemplo.bpmn"
        self.mydoc = minidom.parse('ejemplo.bpmn')
        self.get_tasks()
        self.get_lanes()
        self.get_dataobjects()
        self.asignar_lane_a_tasks()
        self.guardar_proceso()
        self.guardar_tareas()
        self.guardar_tiposdocumento()
        self.guardar_responsabilidades()

    def get_tasks(self):
        if not hasattr(self, 'tasks'):
            self.tasks = self.mydoc.getElementsByTagName('bpmn:task')
            for task in self.tasks:
                task.name = task.getAttribute('name')
                task.id = task.getAttribute('id')
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
            defaults = {'dias_habiles_max_duracion': 1,
                        'orden': orden}
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


b = Bpmn()
