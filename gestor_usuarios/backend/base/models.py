from datetime import date, datetime
from django.db import models
from django.db.models.fields import related


class Accesos(models.Model):
    id_acceso = models.BigAutoField(db_column='ID_ACCESO', primary_key=True)
    a_nombre_acceso = models.CharField(db_column='A_NOMBRE_ACCESO', max_length=20, blank=True, null=True)
    a_valor_acceso_char = models.CharField(db_column='A_VALOR_ACCESO_CHAR', max_length=100, blank=True, null=True)
    d_fecha_creacion = models.DateTimeField(db_column='D_FECHA_CREACION', blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'SGDP_ACCESOS'


class AccionesHistInstDeTareas(models.Model):
    id_accion_historico_inst_de_tarea = models.BigIntegerField(db_column='ID_ACCION_HISTORICO_INST_DE_TAREA', primary_key=True)
    a_nombre_accion = models.CharField(db_column='A_NOMBRE_ACCION', max_length=30)
    a_desc_accion = models.CharField(db_column='A_DESC_ACCION', max_length=255, blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'SGDP_ACCIONES_HIST_INST_DE_TAREAS'


class ArchivosInstDeTarea(models.Model):
    id_archivos_inst_de_tarea = models.BigIntegerField(db_column='ID_ARCHIVOS_INST_DE_TAREA', primary_key=True)
    id_instancia_de_tarea = models.ForeignKey('InstanciasDeTareas', models.DO_NOTHING, db_column='ID_INSTANCIA_DE_TAREA')
    a_nombre_archivo = models.CharField(db_column='A_NOMBRE_ARCHIVO', max_length=1000)
    a_mime_type = models.CharField(db_column='A_MIME_TYPE', max_length=100, blank=True, null=True)
    id_archivo_cms = models.CharField(db_column='ID_ARCHIVO_CMS', max_length=100)
    a_version = models.CharField(db_column='A_VERSION', max_length=100)
    id_tipo_de_documento = models.ForeignKey('TipoDeDocumento', models.DO_NOTHING, db_column='ID_TIPO_DE_DOCUMENTO', blank=True, null=True)
    id_usuario = models.CharField(db_column='ID_USUARIO', max_length=30, blank=True, null=True)
    d_fecha_subido = models.DateTimeField(db_column='D_FECHA_SUBIDO', blank=True, null=True)
    b_esta_visado = models.BooleanField(db_column='B_ESTA_VISADO', blank=True, null=True)
    b_esta_firmado_con_fea_web_start = models.BooleanField(db_column='B_ESTA_FIRMADO_CON_FEA_WEB_START', blank=True, null=True)
    b_esta_firmado_con_fea_centralizada = models.BooleanField(db_column='B_ESTA_FIRMADO_CON_FEA_CENTRALIZADA', blank=True, null=True)
    d_fecha_documento = models.DateTimeField(db_column='D_FECHA_DOCUMENTO', blank=True, null=True)
    d_fecha_recepcion = models.DateTimeField(db_column='D_FECHA_RECEPCION', blank=True, null=True)

    id_archivos_inst_de_tarea_metadata = models.ForeignKey('ArchivosInstDeTareaMetadata', models.DO_NOTHING, db_column='ID_ARCHIVOS_INST_DE_TAREA_METADATA', blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'SGDP_ARCHIVOS_INST_DE_TAREA'


class ArchivosInstDeTareaMetadata(models.Model):
    id_archivos_inst_de_tarea_metadata = models.BigAutoField(db_column='ID_ARCHIVOS_INST_DE_TAREA_METADATA', primary_key=True)
    id_tipo = models.ForeignKey('Tipos', models.DO_NOTHING, db_column='ID_TIPO', blank=True, null=True)
    a_titulo = models.CharField(db_column='A_TITULO', max_length=200, blank=True, null=True)
    a_autor = models.CharField(db_column='A_AUTOR', max_length=200, blank=True, null=True)
    a_destinatarios = models.CharField(db_column='A_DESTINATARIOS', max_length=1000, blank=True, null=True)
    b_digitalizado = models.BooleanField(db_column='B_DIGITALIZADO', blank=True, null=True)
    d_fecha_documento = models.DateTimeField(db_column='D_FECHA_DOCUMENTO', blank=True, null=True)
    a_nombre_interesado = models.CharField(db_column='A_NOMBRE_INTERESADO', max_length=200, blank=True, null=True)
    a_apellido_paterno = models.CharField(db_column='A_APELLIDO_PATERNO', max_length=200, blank=True, null=True)
    a_apellido_materno = models.CharField(db_column='A_APELLIDO_MATERNO', max_length=200, blank=True, null=True)
    a_rut = models.CharField(db_column='A_RUT', max_length=20, blank=True, null=True)
    a_etiquetas = models.CharField(db_column='A_ETIQUETAS', max_length=1000, blank=True, null=True)
    a_region = models.CharField(db_column='A_REGION', max_length=200, blank=True, null=True)
    a_comuna = models.CharField(db_column='A_COMUNA', max_length=200, blank=True, null=True)
    a_metadata_custom = models.TextField(db_column='A_METADATA_CUSTOM', blank=True, null=True)
    n_flag_envio = models.BigIntegerField(db_column='N_FLAG_ENVIO', blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'SGDP_ARCHIVOS_INST_DE_TAREA_METADATA'


class AsignacionesNumerosDoc(models.Model):
    id_asignacion_numero_doc = models.BigIntegerField(db_column='ID_ASIGNACION_NUMERO_DOC', primary_key=True)
    n_numero_documento = models.BigIntegerField(db_column='N_NUMERO_DOCUMENTO')
    id_tipo_de_documento = models.ForeignKey('TipoDeDocumento', models.DO_NOTHING, db_column='ID_TIPO_DE_DOCUMENTO')
    a_estado = models.CharField(db_column='A_ESTADO', max_length=255, blank=True, null=True)
    d_anio = models.CharField(db_column='D_ANIO', max_length=255)
    d_fecha_creacion = models.DateTimeField(db_column='D_FECHA_CREACION')
    d_fecha_modificacion = models.DateTimeField(db_column='D_FECHA_MODIFICACION', blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'SGDP_ASIGNACIONES_NUMEROS_DOC'


class Autores(models.Model):
    id_autor = models.BigAutoField(db_column='ID_AUTOR', primary_key=True)
    a_nombre_autor = models.CharField(db_column='A_NOMBRE_AUTOR', max_length=100)

    class Meta:
        managed = False
        db_table = 'SGDP_AUTORES'


class Cargas(models.Model):
    id_carga = models.BigAutoField(db_column='ID_CARGA', primary_key=True)
    n_cantidad_documentos = models.BigIntegerField(db_column='N_CANTIDAD_DOCUMENTOS')
    a_nombre_serie = models.CharField(db_column='A_NOMBRE_SERIE', max_length=200, blank=True, null=True)
    a_nombre_acuerdo = models.CharField(db_column='A_NOMBRE_ACUERDO', max_length=200, blank=True, null=True)
    a_tipo_acuerdo = models.CharField(db_column='A_TIPO_ACUERDO', max_length=200, blank=True, null=True)
    a_id_transferencia = models.CharField(db_column='A_ID_TRANSFERENCIA', max_length=500, blank=True, null=True)
    d_fecha_creacion = models.DateTimeField(db_column='D_FECHA_CREACION', blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'SGDP_CARGAS'


class Cargo(models.Model):
    id_cargo = models.BigIntegerField(db_column='ID_CARGO', unique=True)
    a_nombre_cargo = models.CharField(db_column='A_NOMBRE_CARGO', max_length=255)

    class Meta:
        managed = False
        db_table = 'SGDP_CARGO'


class CargoResponsabilidad(models.Model):
    id_cargo = models.ForeignKey(Cargo, models.DO_NOTHING, db_column='ID_CARGO')
    id_responsabilidad = models.ForeignKey('Responsabilidad', models.DO_NOTHING, db_column='ID_RESPONSABILIDAD')

    class Meta:
        managed = False
        db_table = 'SGDP_CARGO_RESPONSABILIDAD'


class CargoUsuarioRol(models.Model):
    id_cargo = models.ForeignKey(Cargo, models.DO_NOTHING, db_column='ID_CARGO')
    id_usuario_rol = models.ForeignKey('UsuariosRoles', models.DO_NOTHING, db_column='ID_USUARIO_ROL')

    class Meta:
        managed = False
        db_table = 'SGDP_CARGO_USUARIO_ROL'


class CategoriaDeTipoDeDocumento(models.Model):
    """Parece que no se ocupa"""
    id_categoria_de_tipo_de_documento = models.BigAutoField(db_column='ID_CATEGORIA_DE_TIPO_DE_DOCUMENTO', primary_key=True)
    a_nombre_de_categoria_de_tipo_de_documento = models.TextField(db_column='A_NOMBRE_DE_CATEGORIA_DE_TIPO_DE_DOCUMENTO')

    class Meta:
        managed = False
        db_table = 'SGDP_CATEGORIA_DE_TIPO_DE_DOCUMENTO'


class DetallesCarga(models.Model):
    id_detalle_carga = models.BigAutoField(db_column='ID_DETALLE_CARGA', primary_key=True)
    id_carga = models.ForeignKey(Cargas, models.DO_NOTHING, db_column='ID_CARGA')
    a_nombre_documento = models.CharField(db_column='A_NOMBRE_DOCUMENTO', max_length=200, blank=True, null=True)
    a_id_archivo_cms = models.CharField(db_column='A_ID_ARCHIVO_CMS', max_length=200, blank=True, null=True)
    d_fecha_creacion = models.DateTimeField(db_column='D_FECHA_CREACION', blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'SGDP_DETALLES_CARGA'


class DocumentosDeSalidaDeTareas(models.Model):
    id_tarea = models.ForeignKey('Tarea', models.DO_NOTHING, db_column='ID_TAREA', primary_key=True)
    id_tipo_de_documento = models.ForeignKey('TipoDeDocumento', models.DO_NOTHING, db_column='ID_TIPO_DE_DOCUMENTO')
    n_orden = models.IntegerField(db_column='N_ORDEN', blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'SGDP_DOCUMENTOS_DE_SALIDA_DE_TAREAS'
        unique_together = (('id_tarea', 'id_tipo_de_documento'),)


class EstadosDeProcesos(models.Model):
    id_estado_de_proceso = models.BigAutoField(db_column='ID_ESTADO_DE_PROCESO', primary_key=True)
    n_codigo_estado_de_proceso = models.IntegerField(db_column='N_CODIGO_ESTADO_DE_PROCESO')
    a_nombre_estado_de_proceso = models.CharField(db_column='A_NOMBRE_ESTADO_DE_PROCESO', max_length=30, blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'SGDP_ESTADOS_DE_PROCESOS'


class EstadosDeTareas(models.Model):
    id_estado_de_tarea = models.BigAutoField(db_column='ID_ESTADO_DE_TAREA', primary_key=True)
    n_codigo_estado_de_tarea = models.IntegerField(db_column='N_CODIGO_ESTADO_DE_TAREA')
    a_nombre_estado_de_tarea = models.CharField(db_column='A_NOMBRE_ESTADO_DE_TAREA', max_length=20)

    class Meta:
        managed = False
        db_table = 'SGDP_ESTADOS_DE_TAREAS'


class EstadoSolicitudCreacionExp(models.Model):
    id_estado_solicitud_creacion_exp = models.BigAutoField(db_column='ID_ESTADO_SOLICITUD_CREACION_EXP', primary_key=True)
    a_nombre_estado_solicitud_creacion_exp = models.CharField(db_column='A_NOMBRE_ESTADO_SOLICITUD_CREACION_EXP', max_length=20)

    class Meta:
        managed = False
        db_table = 'SGDP_ESTADO_SOLICITUD_CREACION_EXP'


class Etapa(models.Model):
    id = models.BigAutoField(db_column='ID_ETAPA', primary_key=True)
    nombre = models.CharField(db_column='A_NOMBRE_ETAPA', max_length=30)

    class Meta:
        managed = False
        db_table = 'SGDP_ETAPAS'
        ordering = ['id']


class FechasFeriados(models.Model):
    a_fecha_feriado = models.CharField(db_column='A_FECHA_FERIADO', primary_key=True, max_length=10)
    d_fecha_feriado = models.DateTimeField(db_column='D_FECHA_FERIADO', blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'SGDP_FECHAS_FERIADOS'


class HistoricoAccionesInstDeTareas(models.Model):
    id_historico_acciones_inst_de_tareas = models.BigIntegerField(db_column='ID_HISTORICO_ACCIONES_INST_DE_TAREAS', primary_key=True)
    a_nombre_accion = models.CharField(db_column='A_NOMBRE_ACCION', max_length=30)

    class Meta:
        managed = False
        db_table = 'SGDP_HISTORICO_ACCIONES_INST_DE_TAREAS'


class HistoricoArchivosInstDeTareas(models.Model):
    id_historico_de_inst_de_tarea = models.ForeignKey('HistoricoDeInstDeTareas', models.DO_NOTHING, db_column='ID_HISTORICO_DE_INST_DE_TAREA')
    a_nombre_archivo = models.CharField(db_column='A_NOMBRE_ARCHIVO', max_length=1000)
    a_mime_type = models.CharField(db_column='A_MIME_TYPE', max_length=100, blank=True, null=True)
    id_archivo_cms = models.CharField(db_column='ID_ARCHIVO_CMS', max_length=100)
    a_version = models.CharField(db_column='A_VERSION', max_length=100)
    id_historico_archivos_inst_de_tareas = models.BigIntegerField(db_column='ID_HISTORICO_ARCHIVOS_INST_DE_TAREAS', primary_key=True)
    id_tipo_de_documento = models.ForeignKey('TipoDeDocumento', models.DO_NOTHING, db_column='ID_TIPO_DE_DOCUMENTO', blank=True, null=True)
    id_usuario = models.CharField(db_column='ID_USUARIO', max_length=30, blank=True, null=True)
    d_fecha_documento = models.DateTimeField(db_column='D_FECHA_DOCUMENTO', blank=True, null=True)
    d_fecha_recepcion = models.DateTimeField(db_column='D_FECHA_RECEPCION', blank=True, null=True)
    d_fecha_subido = models.DateTimeField(db_column='D_FECHA_SUBIDO', blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'SGDP_HISTORICO_ARCHIVOS_INST_DE_TAREAS'


class HistoricoDeInstDeTareas(models.Model):
    id_historico_de_inst_de_tarea = models.BigIntegerField(db_column='ID_HISTORICO_DE_INST_DE_TAREA', primary_key=True)
    id_instancia_de_tarea_de_origen = models.ForeignKey('InstanciasDeTareas', models.DO_NOTHING, db_column='ID_INSTANCIA_DE_TAREA_DE_ORIGEN', related_name='origenes')
    d_fecha_movimiento = models.DateTimeField(db_column='D_FECHA_MOVIMIENTO')
    id_accion_historico_inst_de_tarea = models.ForeignKey(AccionesHistInstDeTareas, models.DO_NOTHING, db_column='ID_ACCION_HISTORICO_INST_DE_TAREA')
    id_usuario_origen = models.CharField(db_column='ID_USUARIO_ORIGEN', max_length=30)
    id_instancia_de_tarea_destino = models.ForeignKey('InstanciasDeTareas', models.DO_NOTHING, db_column='ID_INSTANCIA_DE_TAREA_DESTINO', related_name='destinos')
    a_comentario = models.TextField(db_column='A_COMENTARIO', blank=True, null=True)
    a_mensaje_excepcion = models.TextField(db_column='A_MENSAJE_EXCEPCION', blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'SGDP_HISTORICO_DE_INST_DE_TAREAS'


class HistoricoFechaVencInsProc(models.Model):
    id_hist_fecha_venc_ins_proc = models.BigIntegerField(db_column='ID_HIST_FECHA_VENC_INS_PROC', unique=True)
    id_instancia_de_tarea = models.ForeignKey('InstanciasDeTareas', models.DO_NOTHING, db_column='ID_INSTANCIA_DE_TAREA')
    d_fecha_vencimiento = models.DateTimeField(db_column='D_FECHA_VENCIMIENTO')
    id_usuario = models.CharField(db_column='ID_USUARIO', max_length=30)

    class Meta:
        managed = False
        db_table = 'SGDP_HISTORICO_FECHA_VENC_INS_PROC'


class HistoricoFirmas(models.Model):
    id_historico_firma = models.BigIntegerField(db_column='ID_HISTORICO_FIRMA', unique=True)
    id_instancia_de_tarea = models.ForeignKey('InstanciasDeTareas', models.DO_NOTHING, db_column='ID_INSTANCIA_DE_TAREA')
    id_archivo_cms = models.CharField(db_column='ID_ARCHIVO_CMS', max_length=100)
    id_usuario = models.CharField(db_column='ID_USUARIO', max_length=30)
    d_fecha_firma = models.DateTimeField(db_column='D_FECHA_FIRMA')
    a_tipo_firma = models.CharField(db_column='A_TIPO_FIRMA', max_length=100)
    id_tipo_de_documento = models.ForeignKey('TipoDeDocumento', models.DO_NOTHING, db_column='ID_TIPO_DE_DOCUMENTO')

    class Meta:
        managed = False
        db_table = 'SGDP_HISTORICO_FIRMAS'


class HistoricoSeguimientoIntanciaProcesos(models.Model):
    id_historico_instancia_proceso = models.BigAutoField(db_column='ID_HISTORICO_INSTANCIA_PROCESO', primary_key=True)
    id_instancia_proceso = models.BigIntegerField(db_column='ID_INSTANCIA_PROCESO', blank=True, null=True)
    id_usuario = models.CharField(db_column='ID_USUARIO', max_length=255, blank=True, null=True)
    id_usuario_accion = models.CharField(db_column='ID_USUARIO_ACCION', max_length=255, blank=True, null=True)
    a_accion = models.CharField(db_column='A_ACCION', max_length=255, blank=True, null=True)
    d_fecha_accion = models.DateTimeField(db_column='D_FECHA_ACCION', blank=True, null=True)
    a_tipo_de_notificacion = models.CharField(db_column='A_TIPO_DE_NOTIFICACION', max_length=255, blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'SGDP_HISTORICO_SEGUIMIENTO_INTANCIA_PROCESOS'


class HistoricoSolicitudCreacionExp(models.Model):
    id_historico_solicitud_creacion_exp = models.BigAutoField(db_column='ID_HISTORICO_SOLICITUD_CREACION_EXP', primary_key=True)
    id_solicitud_creacion_exp = models.ForeignKey('SolicitudCreacionExp', models.DO_NOTHING, db_column='ID_SOLICITUD_CREACION_EXP')
    id_instancia_de_proceso = models.ForeignKey('InstanciasDeProcesos', models.DO_NOTHING, db_column='ID_INSTANCIA_DE_PROCESO', blank=True, null=True)
    id_usuario_solicitante = models.CharField(db_column='ID_USUARIO_SOLICITANTE', max_length=30)
    id_usuario_creador_expediente = models.CharField(db_column='ID_USUARIO_CREADOR_EXPEDIENTE', max_length=30, blank=True, null=True)
    id_usuario_destinatario = models.CharField(db_column='ID_USUARIO_DESTINATARIO', max_length=30, blank=True, null=True)
    d_fecha_solicitud = models.DateTimeField(db_column='D_FECHA_SOLICITUD')
    d_fecha_atencion = models.DateTimeField(db_column='D_FECHA_ATENCION', blank=True, null=True)
    a_comentario = models.TextField(db_column='A_COMENTARIO', blank=True, null=True)
    id_estado_solicitud_creacion_exp = models.ForeignKey(EstadoSolicitudCreacionExp, models.DO_NOTHING, db_column='ID_ESTADO_SOLICITUD_CREACION_EXP')
    id_proceso = models.ForeignKey('Proceso', models.DO_NOTHING, db_column='ID_PROCESO', blank=True, null=True)
    a_asunto_materia = models.CharField(db_column='A_ASUNTO_MATERIA', max_length=1000)
    id_autor = models.ForeignKey(Autores, models.DO_NOTHING, db_column='ID_AUTOR', blank=True, null=True)
    id_usuario = models.CharField(db_column='ID_USUARIO', max_length=30)
    d_fecha = models.DateTimeField(db_column='D_FECHA')
    a_tipo_accion = models.CharField(db_column='A_TIPO_ACCION', max_length=100)

    class Meta:
        managed = False
        db_table = 'SGDP_HISTORICO_SOLICITUD_CREACION_EXP'


class HistoricoUsuariosAsignadosATareas(models.Model):
    id_historico_de_inst_de_tarea = models.ForeignKey(HistoricoDeInstDeTareas, models.DO_NOTHING, db_column='ID_HISTORICO_DE_INST_DE_TAREA', primary_key=True)
    id_usuario = models.CharField(db_column='ID_USUARIO', max_length=100)

    class Meta:
        managed = False
        db_table = 'SGDP_HISTORICO_USUARIOS_ASIGNADOS_A_TAREAS'
        unique_together = (('id_historico_de_inst_de_tarea', 'id_usuario'),)


class HistoricoValorParametroDeTarea(models.Model):
    id_historico_valor_parametro_de_tarea = models.BigAutoField(db_column='ID_HISTORICO_VALOR_PARAMETRO_DE_TAREA', primary_key=True)
    id_param_tarea = models.ForeignKey('ParametroDeTarea', models.DO_NOTHING, db_column='ID_PARAM_TAREA')
    a_valor = models.CharField(db_column='A_VALOR', max_length=5000, blank=True, null=True)
    a_comentario = models.CharField(db_column='A_COMENTARIO', max_length=10000, blank=True, null=True)
    id_historico_de_inst_de_tarea = models.ForeignKey(HistoricoDeInstDeTareas, models.DO_NOTHING, db_column='ID_HISTORICO_DE_INST_DE_TAREA')

    class Meta:
        managed = False
        db_table = 'SGDP_HISTORICO_VALOR_PARAMETRO_DE_TAREA'


class HistoricoVinculacionExp(models.Model):
    id_historico_vinculacion_exp = models.BigIntegerField(db_column='ID_HISTORICO_VINCULACION_EXP', primary_key=True)
    id_instancia_de_proceso = models.ForeignKey('InstanciasDeProcesos', models.DO_NOTHING, db_column='ID_INSTANCIA_DE_PROCESO', related_name='procesos')

    id_instancia_de_proceso_antecesor = models.ForeignKey('InstanciasDeProcesos', models.DO_NOTHING, db_column='ID_INSTANCIA_DE_PROCESO_ANTECESOR', related_name='antecesores')
    id_usuario = models.CharField(db_column='ID_USUARIO', max_length=30)
    d_fecha = models.DateTimeField(db_column='D_FECHA')
    a_tipo_accion = models.CharField(db_column='A_TIPO_ACCION', max_length=100)
    a_comentario = models.TextField(db_column='A_COMENTARIO')
    b_vigente = models.BooleanField(db_column='B_VIGENTE', blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'SGDP_HISTORICO_VINCULACION_EXP'


class InstanciasDeProcesos(models.Model):
    id = models.BigAutoField(db_column='ID_INSTANCIA_DE_PROCESO', primary_key=True)
    proceso = models.ForeignKey('Proceso', models.DO_NOTHING, db_column='ID_PROCESO')
    fecha_inicio = models.DateTimeField(db_column='D_FECHA_INICIO')
    d_fecha_fin = models.DateTimeField(db_column='D_FECHA_FIN', blank=True, null=True)
    a_nombre_expediente = models.CharField(db_column='A_NOMBRE_EXPEDIENTE', max_length=100, blank=True, null=True)
    d_fecha_vencimiento_usuario = models.DateTimeField(db_column='D_FECHA_VENCIMIENTO_USUARIO', blank=True, null=True)
    estado_de_proceso = models.ForeignKey(EstadosDeProcesos, models.DO_NOTHING, db_column='ID_ESTADO_DE_PROCESO')
    id_expediente = models.CharField(db_column='ID_EXPEDIENTE', max_length=100, blank=True, null=True)
    id_instancia_de_proceso_padre = models.ForeignKey('self', models.DO_NOTHING, db_column='ID_INSTANCIA_DE_PROCESO_PADRE', blank=True, null=True)
    id_usuario_inicia = models.CharField(db_column='ID_USUARIO_INICIA', max_length=30)
    id_usuario_termina = models.CharField(db_column='ID_USUARIO_TERMINA', max_length=30, blank=True, null=True)
    b_tiene_documentos_en_cms = models.BooleanField(db_column='B_TIENE_DOCUMENTOS_EN_CMS', blank=True, null=True)
    d_fecha_vencimiento = models.DateTimeField(db_column='D_FECHA_VENCIMIENTO', blank=True, null=True)
    emisor = models.CharField(db_column='A_EMISOR', max_length=1000, blank=True, null=True)
    a_asunto = models.CharField(db_column='A_ASUNTO', max_length=1000, blank=True, null=True)
    unidad = models.ForeignKey('Unidades', models.DO_NOTHING, db_column='ID_UNIDAD', blank=True, null=True)
    acceso = models.ForeignKey(Accesos, models.DO_NOTHING, db_column='ID_ACCESO', blank=True, null=True)
    id_instancia_proceso_metadata = models.ForeignKey('InstanciaProcesoMetadata', models.DO_NOTHING, db_column='ID_INSTANCIA_PROCESO_METADATA', blank=True, null=True)
    tipo = models.ForeignKey('Tipos', models.DO_NOTHING, db_column='ID_TIPO', blank=True, null=True)
    d_fecha_expiracion = models.DateTimeField(db_column='D_FECHA_EXPIRACION', blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'SGDP_INSTANCIAS_DE_PROCESOS'


class InstanciasDeTareas(models.Model):
    id = models.BigIntegerField(db_column='ID_INSTANCIA_DE_TAREA', primary_key=True)
    instancia_de_proceso = models.ForeignKey(InstanciasDeProcesos, models.DO_NOTHING, db_column='ID_INSTANCIA_DE_PROCESO')
    tarea = models.ForeignKey('Tarea', models.DO_NOTHING, db_column='ID_TAREA')
    fecha_asignacion = models.DateTimeField(db_column='D_FECHA_ASIGNACION')
    fecha_inicio = models.DateTimeField(db_column='D_FECHA_INICIO', blank=True, null=True)
    fecha_finalizacion = models.DateTimeField(db_column='D_FECHA_FINALIZACION', blank=True, null=True)
    fecha_anulacion = models.DateTimeField(db_column='D_FECHA_ANULACION', blank=True, null=True)
    razon_anulacion = models.CharField(db_column='A_RAZON_ANULACION', max_length=1000, blank=True, null=True)
    fecha_vencimiento = models.DateTimeField(db_column='D_FECHA_VENCIMIENTO', blank=True, null=True)
    estado_de_tarea = models.ForeignKey(EstadosDeTareas, models.DO_NOTHING, db_column='ID_ESTADO_DE_TAREA', blank=True, null=True)
    fecha_vencimiento_usuario = models.DateTimeField(db_column='D_FECHA_VENCIMIENTO_USUARIO', blank=True, null=True)
    usuario_que_asigna = models.CharField(db_column='ID_USUARIO_QUE_ASIGNA', max_length=30, blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'SGDP_INSTANCIAS_DE_TAREAS'


class InstanciasDeTareasLibres(models.Model):
    id_instancia_de_tarea_libre = models.BigAutoField(db_column='ID_INSTANCIA_DE_TAREA_LIBRE', primary_key=True)
    id_usuario_que_hace_consulta = models.CharField(db_column='ID_USUARIO_QUE_HACE_CONSULTA', max_length=30)
    id_usuario_asigando = models.CharField(db_column='ID_USUARIO_ASIGANDO', max_length=30)
    id_instancia_de_tarea = models.BigIntegerField(db_column='ID_INSTANCIA_DE_TAREA')
    d_fecha_asignacion = models.DateTimeField(db_column='D_FECHA_ASIGNACION')
    d_fecha_finalizacion = models.DateTimeField(db_column='D_FECHA_FINALIZACION', blank=True, null=True)
    id_estado_de_tarea = models.ForeignKey(EstadosDeTareas, models.DO_NOTHING, db_column='ID_ESTADO_DE_TAREA')
    d_fecha_vencimiento = models.DateTimeField(db_column='D_FECHA_VENCIMIENTO', blank=True, null=True)
    id_tipo_de_tarea_libre = models.ForeignKey('TiposDeTareasLibres', models.DO_NOTHING, db_column='ID_TIPO_DE_TAREA_LIBRE')
    id_instancia_de_tarea_libre_padre = models.ForeignKey('self', models.DO_NOTHING, db_column='ID_INSTANCIA_DE_TAREA_LIBRE_PADRE', blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'SGDP_INSTANCIAS_DE_TAREAS_LIBRES'


class InstanciaProcesoMetadata(models.Model):
    id_instancia_proceso_metadata = models.BigAutoField(db_column='ID_INSTANCIA_PROCESO_METADATA', primary_key=True)
    a_titulo = models.CharField(db_column='A_TITULO', max_length=200, blank=True, null=True)
    a_nombre_interesado = models.CharField(db_column='A_NOMBRE_INTERESADO', max_length=200, blank=True, null=True)
    a_apellido_paterno = models.CharField(db_column='A_APELLIDO_PATERNO', max_length=200, blank=True, null=True)
    a_apellido_materno = models.CharField(db_column='A_APELLIDO_MATERNO', max_length=200, blank=True, null=True)
    a_rut = models.CharField(db_column='A_RUT', max_length=20, blank=True, null=True)
    a_etiquetas = models.CharField(db_column='A_ETIQUETAS', max_length=1000, blank=True, null=True)
    a_region = models.CharField(db_column='A_REGION', max_length=200, blank=True, null=True)
    a_comuna = models.CharField(db_column='A_COMUNA', max_length=200, blank=True, null=True)
    a_metadata_custom = models.TextField(db_column='A_METADATA_CUSTOM', blank=True, null=True)
    d_fecha_creacion = models.DateTimeField(db_column='D_FECHA_CREACION', blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'SGDP_INSTANCIA_PROCESO_METADATA'


class ListaDeDistribucion(models.Model):
    # id_lista_de_distribucion = models.BigAutoField(db_column='ID_LISTA_DE_DISTRIBUCION')
    # a_nombre_completo = models.CharField(db_column='A_NOMBRE_COMPLETO', max_length=5000)
    a_email = models.CharField(db_column='A_EMAIL', max_length=5000)
    a_organizacion = models.CharField(db_column='A_ORGANIZACION', max_length=10000, blank=True, null=True)
    a_cargo = models.CharField(db_column='A_CARGO', max_length=10000, blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'SGDP_LISTA_DE_DISTRIBUCION'


class LogCarga(models.Model):
    id_log_carga = models.BigAutoField(db_column='ID_LOG_CARGA', primary_key=True)
    id_carga = models.ForeignKey(Cargas, models.DO_NOTHING, db_column='ID_CARGA')
    a_descripcion = models.CharField(db_column='A_DESCRIPCION', max_length=1000, blank=True, null=True)
    d_fecha_creacion = models.DateTimeField(db_column='D_FECHA_CREACION', blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'SGDP_LOG_CARGA'


class LogError(models.Model):
    id_log_error = models.BigAutoField(db_column='ID_LOG_ERROR', primary_key=True)
    a_nombre_error = models.CharField(db_column='A_NOMBRE_ERROR', max_length=30)
    a_mensaje_excepcion = models.TextField(db_column='A_MENSAJE_EXCEPCION')
    d_fecha_error = models.DateTimeField(db_column='D_FECHA_ERROR')
    id_usuario = models.CharField(db_column='ID_USUARIO', max_length=30)
    a_datos_adicionales = models.TextField(db_column='A_DATOS_ADICIONALES', blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'SGDP_LOG_ERROR'


class LogFueraDeOficina(models.Model):
    id_log_fuera_de_oficina = models.BigIntegerField(db_column='ID_LOG_FUERA_DE_OFICINA', unique=True)
    id_usuario = models.CharField(db_column='ID_USUARIO', max_length=30)
    d_fecha_actualizacion = models.DateTimeField(db_column='D_FECHA_ACTUALIZACION')
    b_fuera_de_oficina = models.BooleanField(db_column='B_FUERA_DE_OFICINA')

    class Meta:
        managed = False
        db_table = 'SGDP_LOG_FUERA_DE_OFICINA'


class LogTransacciones(models.Model):
    id_log_transaccion = models.BigIntegerField(db_column='ID_LOG_TRANSACCION', primary_key=True)
    a_nombre_tabla = models.CharField(db_column='A_NOMBRE_TABLA', max_length=30)
    a_accion = models.CharField(db_column='A_ACCION', max_length=30)
    id_usuario = models.CharField(db_column='ID_USUARIO', max_length=30)
    d_fecha_transaccion = models.DateTimeField(db_column='D_FECHA_TRANSACCION', blank=True, null=True)
    a_parametros = models.CharField(db_column='A_PARAMETROS', max_length=4000)

    class Meta:
        managed = False
        db_table = 'SGDP_LOG_TRANSACCIONES'


class Macroproceso(models.Model):
    id = models.BigAutoField(db_column='ID_MACRO_PROCESO', primary_key=True)
    nombre = models.CharField(db_column='A_NOMBRE_MACRO_PROCESO', max_length=100)
    descripcion = models.CharField(db_column='A_DESCRIPCION_MACRO_PROCESO', max_length=100, blank=True, null=True)
    id_perspectiva = models.ForeignKey('Perspectivas', models.DO_NOTHING, db_column='ID_PERSPECTIVA')

    class Meta:
        managed = False
        db_table = 'SGDP_MACRO_PROCESOS'
        ordering = ['nombre']


class Parametro(models.Model):
    id = models.BigAutoField(db_column='ID_PARAMETRO', primary_key=True)
    nombre = models.CharField(db_column='A_NOMBRE_PARAMETRO', max_length=200, blank=True, null=True)
    valor_parametro_char = models.CharField(db_column='A_VALOR_PARAMETRO_CHAR', max_length=10000, blank=True, null=True)
    valor_parametro_numerico = models.IntegerField(db_column='N_VALOR_PARAMETRO_NUMERICO', blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'SGDP_PARAMETROS'


class ParametrosArchivoNacional(models.Model):
    id_parametro_archivo_nacional = models.BigAutoField(db_column='ID_PARAMETRO_ARCHIVO_NACIONAL', primary_key=True)
    a_nombre_parametro = models.CharField(db_column='A_NOMBRE_PARAMETRO', max_length=200, blank=True, null=True)
    a_valor_parametro_char = models.CharField(db_column='A_VALOR_PARAMETRO_CHAR', max_length=100, blank=True, null=True)
    d_fecha_creacion = models.DateTimeField(db_column='D_FECHA_CREACION', blank=True, null=True)
    d_fecha_actualizacion = models.DateTimeField(db_column='D_FECHA_ACTUALIZACION', blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'SGDP_PARAMETROS_ARCHIVO_NACIONAL'


class ParametrosPorContexto(models.Model):
    id_parametro_por_contexto = models.BigAutoField(db_column='ID_PARAMETRO_POR_CONTEXTO', primary_key=True)
    a_nombre_parametro = models.CharField(db_column='A_NOMBRE_PARAMETRO', max_length=250, blank=True, null=True)
    a_valor_contexto = models.CharField(db_column='A_VALOR_CONTEXTO', max_length=250, blank=True, null=True)
    a_valor_parametro_char = models.TextField(db_column='A_VALOR_PARAMETRO_CHAR', blank=True, null=True)
    n_valor_parametro_numerico = models.IntegerField(db_column='N_VALOR_PARAMETRO_NUMERICO', blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'SGDP_PARAMETROS_POR_CONTEXTO'


class ParametroDeTarea(models.Model):
    id_param_tarea = models.BigAutoField(db_column='ID_PARAM_TAREA', primary_key=True)
    a_nombre_param_tarea = models.CharField(db_column='A_NOMBRE_PARAM_TAREA', max_length=255)
    id_tipo_parametro_de_tarea = models.ForeignKey('TipoParametroDeTarea', models.DO_NOTHING, db_column='ID_TIPO_PARAMETRO_DE_TAREA', blank=True, null=True)
    a_titulo = models.CharField(db_column='A_TITULO', max_length=255, blank=True, null=True)
    vigente = models.BooleanField(db_column='B_VIGENTE', blank=True, null=True)
    # FALTA B_ES_SNC

    class Meta:
        managed = False
        db_table = 'SGDP_PARAMETRO_DE_TAREA'


class ParametroRelacionTarea(models.Model):
    id_tarea = models.ForeignKey('Tarea', models.DO_NOTHING, db_column='ID_TAREA', primary_key=True)
    id_param_tarea = models.ForeignKey(ParametroDeTarea, models.DO_NOTHING, db_column='ID_PARAM_TAREA')

    class Meta:
        managed = False
        db_table = 'SGDP_PARAMETRO_RELACION_TAREA'
        unique_together = (('id_tarea', 'id_param_tarea'),)


class Permiso(models.Model):
    id = models.BigAutoField(db_column='ID_PERMISO', primary_key=True)
    nombre_permiso = models.CharField(db_column='A_NOMBRE_PERMISO', max_length=250)
    rol = models.ForeignKey('Roles', models.DO_NOTHING, db_column='ID_ROL')

    class Meta:
        managed = False
        db_table = 'SGDP_PERMISOS'


class Perspectivas(models.Model):
    id_perspectiva = models.BigAutoField(db_column='ID_PERSPECTIVA', primary_key=True)
    a_nombre_perspectiva = models.CharField(db_column='A_NOMBRE_PERSPECTIVA', max_length=100)
    a_descripcion_perspectiva = models.CharField(db_column='A_DESCRIPCION_PERSPECTIVA', max_length=100, blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'SGDP_PERSPECTIVAS'


class Proceso(models.Model):
    id = models.BigAutoField(db_column='ID_PROCESO', primary_key=True)
    nombre = models.CharField(db_column='A_NOMBRE_PROCESO', max_length=500)
    descripcion = models.CharField(db_column='A_DESCRIPCION_PROCESO', max_length=500, blank=True, null=True)
    macroproceso = models.ForeignKey(Macroproceso, models.DO_NOTHING, db_column='ID_MACRO_PROCESO')
    vigente = models.BooleanField(db_column='B_VIGENTE', blank=True, null=True)
    dias_habiles_max_duracion = models.IntegerField(db_column='N_DIAS_HABILES_MAX_DURACION')
    unidad = models.ForeignKey('Unidades', models.DO_NOTHING, db_column='ID_UNIDAD', blank=True, null=True)
    confidencial = models.BooleanField(db_column='B_CONFIDENCIAL', blank=True, null=True)
    x_bpmn = models.TextField(db_column='X_BPMN', blank=True, null=True)
    codigo_proceso = models.CharField(db_column='A_CODIGO_PROCESO', max_length=20, blank=True, null=True)
    fecha_creacion = models.DateTimeField(db_column='D_FECHA_CREACION', blank=True, null=True)

    def iniciar(**kwargs):
        if kwargs.get("nombre"):
            proceso = Proceso.objects.get(nombre=kwargs.get("nombre"))

        ip = InstanciasDeProcesos(proceso=proceso,
                                  fecha_inicio=datetime.now(),
                                  estado_de_proceso_id=2,
                                  tipo_id=2,
                                  emisor='fingerhuth',
                                  unidad_id=11,
                                  acceso_id=1,
                                  id_usuario_inicia='fingerhuth'
                                  )
        ip.save()

        # temporal
        usuario = UsuariosRoles.objects.filter(id_usuario='fingerhuth').first()
        for rol in Roles.objects.all():
            if UsuariosRoles.objects.filter(id_usuario='fingerhuth', rol=rol).first():
                continue
            usuario.id = None
            usuario.rol = rol
            usuario.save()

        for responsabilidad in Responsabilidad.objects.all():
            ur = UsuarioResponsabilidad.objects.get_or_create(responsabilidad=responsabilidad, id_usuario='fingerhuth')[0]
            ur.n_orden = 1
            ur.save()

        id = InstanciasDeTareas.objects.all().order_by('-id').first() or 0
        for tarea in Tarea.objects.filter(proceso=proceso):
            id += 1
            it = InstanciasDeTareas(instancia_de_proceso=ip,
                                    tarea=tarea,
                                    estado_de_tarea_id=1,
                                    id=id,
                                    usuario_que_asigna='fingerhuth',
                                    fecha_asignacion=datetime.now())

            if tarea.nombre == 'Crear expediente':
                it.estado_de_tarea_id = 3

            if tarea.nombre == 'Solicitar cometido':
                it.estado_de_tarea_id = 2

            it.save()

            UsuariosAsignadosATareas.objects.get_or_create(instancia_de_tarea=it, id_usuario='fingerhuth')
        SeguimientoIntanciaProcesos.objects.get_or_create(id_usuario='fingerhuth', instancia_proceso=ip)

        return ip

    class Meta:
        managed = False
        db_table = 'SGDP_PROCESOS'
        ordering = ['nombre']


class ProcesoFormCreaExp(models.Model):
    id_proceso_form_crea_exp = models.BigAutoField(db_column='ID_PROCESO_FORM_CREA_EXP', primary_key=True)
    a_codigo_proceso = models.CharField(db_column='A_CODIGO_PROCESO', max_length=20, blank=True, null=True)
    id_usuario = models.CharField(db_column='ID_USUARIO', max_length=30)
    d_fecha = models.DateTimeField(db_column='D_FECHA')

    class Meta:
        managed = False
        db_table = 'SGDP_PROCESO_FORM_CREA_EXP'


class ReferenciasDeTarea(models.Model):
    id = models.BigAutoField(db_column='ID_REFERENCIA_DE_TAREA', primary_key=True)
    tarea = models.ForeignKey('Tarea', models.DO_NOTHING, db_column='ID_TAREA', blank=True, null=True, related_name='tareas')
    tarea_siguiente = models.ForeignKey('Tarea', models.DO_NOTHING, db_column='ID_TAREA_SIGUIENTE', blank=True, null=True, related_name='tareas_siguientes')

    class Meta:
        managed = False
        db_table = 'SGDP_REFERENCIAS_DE_TAREAS'


class Responsabilidad(models.Model):
    id = models.BigAutoField(db_column='ID_RESPONSABILIDAD', primary_key=True)
    nombre = models.CharField(db_column='A_NOMBRE_RESPONSABILIDAD', max_length=255)

    class Meta:
        managed = False
        db_table = 'SGDP_RESPONSABILIDAD'
        ordering = ['nombre']


class ResponsabilidadTarea(models.Model):
    responsabilidad = models.ForeignKey(Responsabilidad, models.DO_NOTHING, db_column='ID_RESPONSABILIDAD', primary_key=True)
    tarea = models.ForeignKey('Tarea', models.DO_NOTHING, db_column='ID_TAREA')

    class Meta:
        managed = False
        db_table = 'SGDP_RESPONSABILIDAD_TAREA'
        unique_together = (('responsabilidad', 'tarea'), ('responsabilidad', 'tarea'),)


class Roles(models.Model):
    id = models.BigAutoField(db_column='ID_ROL', primary_key=True)
    nombre = models.CharField(db_column='A_NOMBRE_ROL', max_length=255)

    class Meta:
        managed = False
        db_table = 'SGDP_ROLES'
        ordering = ['nombre']

    # def save(self, *args, **kwargs):
    #     # self.sincronizar_con_responsabilidades()
    #     super(Roles, self).save(*args, **kwargs)
    #     self.sincronizar_con_responsabilidades_temporal()

    # def sincronizar_con_responsabilidades_temporal(self):
    #     for rol in Roles.objects.all():
    #         responsabilidad = Responsabilidad.objects.get_or_create(pk=rol.id)[0]
    #         responsabilidad.nombre = rol.nombre
    #         responsabilidad.save()

    # def sincronizar_con_responsabilidades(self):
    #     if self.id is None:  # Nuevo
    #         Responsabilidad.objects.get_or_create(nombre=self.nombre)

    #     else:  # Cambio Nombre
    #         Responsabilidad.objects.filter(nombre=Roles.objects.get(id=self.id).nombre).update(nombre=self.nombre)


class SeguimientoIntanciaProcesos(models.Model):
    """ 
    Parece que no se ocupa 
    """
    instancia_proceso = models.ForeignKey(InstanciasDeProcesos, models.DO_NOTHING, db_column='ID_INSTANCIA_PROCESO', primary_key=True)
    id_usuario = models.CharField(db_column='ID_USUARIO', max_length=64)
    a_tipo_de_notificacion = models.CharField(db_column='A_TIPO_DE_NOTIFICACION', max_length=255, blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'SGDP_SEGUIMIENTO_INTANCIA_PROCESOS'
        unique_together = (('instancia_proceso', 'id_usuario'),)


class SolicitudCreacionExp(models.Model):
    id_solicitud_creacion_exp = models.BigIntegerField(db_column='ID_SOLICITUD_CREACION_EXP', primary_key=True)
    id_instancia_de_proceso = models.ForeignKey(InstanciasDeProcesos, models.DO_NOTHING, db_column='ID_INSTANCIA_DE_PROCESO', blank=True, null=True)
    id_usuario_solicitante = models.CharField(db_column='ID_USUARIO_SOLICITANTE', max_length=30)
    id_usuario_creador_expediente = models.CharField(db_column='ID_USUARIO_CREADOR_EXPEDIENTE', max_length=30, blank=True, null=True)
    id_usuario_destinatario = models.CharField(db_column='ID_USUARIO_DESTINATARIO', max_length=30, blank=True, null=True)
    d_fecha_solicitud = models.DateTimeField(db_column='D_FECHA_SOLICITUD')
    d_fecha_atencion = models.DateTimeField(db_column='D_FECHA_ATENCION', blank=True, null=True)
    a_comentario = models.TextField(db_column='A_COMENTARIO', blank=True, null=True)
    id_estado_solicitud_creacion_exp = models.ForeignKey(EstadoSolicitudCreacionExp, models.DO_NOTHING, db_column='ID_ESTADO_SOLICITUD_CREACION_EXP')
    id_proceso = models.ForeignKey(Proceso, models.DO_NOTHING, db_column='ID_PROCESO', blank=True, null=True)
    a_asunto_materia = models.CharField(db_column='A_ASUNTO_MATERIA', max_length=1000)
    id_autor = models.ForeignKey(Autores, models.DO_NOTHING, db_column='ID_AUTOR', blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'SGDP_SOLICITUD_CREACION_EXP'


class Tarea(models.Model):
    id = models.BigAutoField(db_column='ID_TAREA', primary_key=True)
    nombre = models.CharField(db_column='A_NOMBRE_TAREA', max_length=500)
    descripcion = models.CharField(db_column='A_DESCRIPCION_TAREA', max_length=500, blank=True, null=True)
    proceso = models.ForeignKey(Proceso, models.DO_NOTHING, db_column='ID_PROCESO')
    dias_habiles_max_duracion = models.IntegerField(db_column='N_DIAS_HABILES_MAX_DURACION')
    orden = models.IntegerField(db_column='N_ORDEN')
    vigente = models.BooleanField(db_column='B_VIGENTE', blank=True, null=True)
    solo_informar = models.BooleanField(db_column='B_SOLO_INFORMAR', blank=True, null=True)
    etapa = models.ForeignKey(Etapa, models.DO_NOTHING, db_column='ID_ETAPA', blank=True, null=True)
    obligatoria = models.BooleanField(db_column='B_OBLIGATORIA', blank=True, null=True)
    es_ultima_tarea = models.BooleanField(db_column='B_ES_ULTIMA_TAREA', blank=True, null=True)
    tipo_de_bifurcacion = models.CharField(db_column='A_TIPO_DE_BIFURCACION', max_length=250, blank=True, null=True)
    puede_visar_documentos = models.BooleanField(db_column='B_PUEDE_VISAR_DOCUMENTOS', blank=True, null=True)
    puede_aplicar_fea = models.BooleanField(db_column='B_PUEDE_APLICAR_FEA', blank=True, null=True)
    url_control = models.CharField(db_column='A_URL_CONTROL', max_length=255, blank=True, null=True)
    id_diagrama = models.CharField(db_column='ID_DIAGRAMA', max_length=1000, blank=True, null=True)
    asigna_num_doc = models.BooleanField(db_column='B_ASIGNA_NUM_DOC', blank=True, null=True)
    esperar_resp = models.BooleanField(db_column='B_ESPERAR_RESP', blank=True, null=True)
    conforma_expediente = models.BooleanField(db_column='B_CONFORMA_EXPEDIENTE', blank=True, null=True)
    dias_reseteo = models.IntegerField(db_column='N_DIAS_RESETEO', blank=True, null=True)
    tipo_reseteo = models.CharField(db_column='A_TIPO_RESETEO', max_length=255, blank=True, null=True)
    url_ws = models.CharField(db_column='A_URL_WS', max_length=250, blank=True, null=True)
    distribuye = models.BooleanField(db_column='B_DISTRIBUYE', blank=True, null=True)
    numeracion_auto = models.BooleanField(db_column='B_NUMERACION_AUTO', blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'SGDP_TAREAS'


class TareasIniciaProcesos(models.Model):
    id_tarea_inicia_proceso = models.BigAutoField(db_column='ID_TAREA_INICIA_PROCESO', primary_key=True)
    id_tarea = models.ForeignKey(Tarea, models.DO_NOTHING, db_column='ID_TAREA')
    id_proceso = models.ForeignKey(Proceso, models.DO_NOTHING, db_column='ID_PROCESO')

    class Meta:
        managed = False
        db_table = 'SGDP_TAREAS_INICIA_PROCESOS'


class TareasRoles(models.Model):
    """ Este modelo no se ocupa """

    id_tarea = models.ForeignKey(Tarea, models.DO_NOTHING, db_column='ID_TAREA', primary_key=True)
    id_rol = models.ForeignKey(Roles, models.DO_NOTHING, db_column='ID_ROL')
    n_orden = models.IntegerField(db_column='N_ORDEN', blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'SGDP_TAREAS_ROLES'
        unique_together = (('id_tarea', 'id_rol'),)


class TextoParametroDeTarea(models.Model):
    id_texto_parametro_de_tarea = models.BigAutoField(db_column='ID_TEXTO_PARAMETRO_DE_TAREA', primary_key=True)
    id_param_tarea = models.ForeignKey(ParametroDeTarea, models.DO_NOTHING, db_column='ID_PARAM_TAREA', blank=True, null=True)
    a_texto = models.CharField(db_column='A_TEXTO', max_length=1000)

    class Meta:
        managed = False
        db_table = 'SGDP_TEXTO_PARAMETRO_DE_TAREA'


class Tipos(models.Model):
    id_tipo = models.BigAutoField(db_column='ID_TIPO', primary_key=True)
    a_nombre_tipo = models.CharField(db_column='A_NOMBRE_TIPO', max_length=20, blank=True, null=True)
    d_fecha_creacion = models.DateTimeField(db_column='D_FECHA_CREACION', blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'SGDP_TIPOS'


class TipoDeDocumento(models.Model):
    id = models.BigAutoField(db_column='ID_TIPO_DE_DOCUMENTO', primary_key=True)
    nombre = models.TextField(db_column='A_NOMBRE_DE_TIPO_DE_DOCUMENTO')
    conforma_expediente = models.BooleanField(db_column='B_CONFORMA_EXPEDIENTE', blank=True, null=True)
    aplica_visacion = models.BooleanField(db_column='B_APLICA_VISACION', blank=True, null=True)
    aplica_fea = models.BooleanField(db_column='B_APLICA_FEA', blank=True, null=True)
    es_documento_conductor = models.BooleanField(db_column='B_ES_DOCUMENTO_CONDUCTOR', blank=True, null=True)

    categoria_de_tipo_de_documento = models.ForeignKey(CategoriaDeTipoDeDocumento, models.DO_NOTHING, db_column='ID_CATEGORIA_DE_TIPO_DE_DOCUMENTO', blank=True, null=True)
    numeracion_auto = models.BooleanField(db_column='B_NUMERACION_AUTO', blank=True, null=True)
    cod_tipo_doc = models.CharField(db_column='A_COD_TIPO_DOC', max_length=255, blank=True, null=True)
    nom_comp_cat_tipo_doc = models.CharField(db_column='A_NOM_COMP_CAT_TIPO_DOC', max_length=255, blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'SGDP_TIPOS_DE_DOCUMENTOS'


class TiposDeTareasLibres(models.Model):
    id_tipo_de_tarea_libre = models.BigIntegerField(db_column='ID_TIPO_DE_TAREA_LIBRE', primary_key=True)
    a_nombre_de_tarea_libre = models.CharField(db_column='A_NOMBRE_DE_TAREA_LIBRE', max_length=100)

    class Meta:
        managed = False
        db_table = 'SGDP_TIPOS_DE_TAREAS_LIBRES'


class TipoParametroDeTarea(models.Model):
    id_tipo_parametro_de_tarea = models.BigAutoField(db_column='ID_TIPO_PARAMETRO_DE_TAREA', primary_key=True)
    a_nombre_tipo_parametro_de_tarea = models.CharField(db_column='A_NOMBRE_TIPO_PARAMETRO_DE_TAREA', max_length=1000)
    a_texto_html = models.CharField(db_column='A_TEXTO_HTML', max_length=5000)
    b_comenta = models.BooleanField(db_column='B_COMENTA', blank=True, null=True)

    # faltan varias columnas

    class Meta:
        managed = False
        db_table = 'SGDP_TIPO_PARAMETRO_DE_TAREA'


class Unidades(models.Model):
    id = models.BigAutoField(db_column='ID_UNIDAD', primary_key=True)
    codigo_unidad = models.CharField(db_column='A_CODIGO_UNIDAD', max_length=30)
    nombre = models.CharField(db_column='A_NOMBRE_COMPLETO_UNIDAD', max_length=100, blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'SGDP_UNIDADES'
        ordering = ['nombre']


class UsuariosAsignadosATareas(models.Model):
    instancia_de_tarea = models.ForeignKey(InstanciasDeTareas, models.DO_NOTHING, db_column='ID_INSTANCIA_DE_TAREA', primary_key=True)
    id_usuario = models.CharField(db_column='ID_USUARIO', max_length=30)

    class Meta:
        managed = False
        db_table = 'SGDP_USUARIOS_ASIGNADOS_A_TAREAS'
        unique_together = (('instancia_de_tarea', 'id_usuario'),)


class UsuariosRoles(models.Model):
    id = models.BigAutoField(db_column='ID_USUARIO_ROL', primary_key=True)
    rol = models.ForeignKey(Roles, models.DO_NOTHING, db_column='ID_ROL')
    id_usuario = models.CharField(db_column='ID_USUARIO', max_length=30)
    unidad = models.ForeignKey(Unidades, models.DO_NOTHING, db_column='ID_UNIDAD', blank=True, null=True)
    activo = models.BooleanField(db_column='B_ACTIVO', blank=True, null=True)
    fuera_de_oficina = models.BooleanField(db_column='B_FUERA_DE_OFICINA', blank=True, null=True)
    nombre_completo = models.CharField(db_column='A_NOMBRE_COMPLETO', max_length=200, blank=True, null=True)
    rut = models.CharField(db_column='A_RUT', max_length=20, blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'SGDP_USUARIOS_ROLES'
        unique_together = (('rol', 'id_usuario'),)


class UsuarioNotificacionTarea(models.Model):
    id_usuario_notificacion_tarea = models.BigAutoField(db_column='ID_USUARIO_NOTIFICACION_TAREA', primary_key=True)
    id_usuario = models.CharField(db_column='ID_USUARIO', max_length=30, blank=True, null=True)
    d_fecha_creacion = models.DateTimeField(db_column='D_FECHA_CREACION', blank=True, null=True)
    id_tarea = models.ForeignKey(Tarea, models.DO_NOTHING, db_column='ID_TAREA', blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'SGDP_USUARIO_NOTIFICACION_TAREA'
        unique_together = (('id_usuario', 'id_tarea'),)


class UsuarioResponsabilidad(models.Model):
    id_usuario = models.CharField(db_column='ID_USUARIO', max_length=255)
    responsabilidad = models.ForeignKey(Responsabilidad, models.DO_NOTHING, db_column='ID_RESPONSABILIDAD')
    usuario = models.BigAutoField(db_column='ID_USUARIO_RESPONSABILIDAD', primary_key=True)
    n_orden = models.IntegerField(db_column='N_ORDEN', blank=True, null=True)
    b_subrogando = models.BooleanField(db_column='B_SUBROGANDO', blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'SGDP_USUARIO_RESPONSABILIDAD'
        unique_together = (('id_usuario', 'responsabilidad'),)


class ValorParametroDeTarea(models.Model):
    id_valor_parametro_de_tarea = models.BigAutoField(db_column='ID_VALOR_PARAMETRO_DE_TAREA', primary_key=True)
    id_param_tarea = models.ForeignKey(ParametroDeTarea, models.DO_NOTHING, db_column='ID_PARAM_TAREA')
    id_instancia_de_tarea = models.ForeignKey(InstanciasDeTareas, models.DO_NOTHING, db_column='ID_INSTANCIA_DE_TAREA')
    a_valor = models.CharField(db_column='A_VALOR', max_length=5000, blank=True, null=True)
    d_fecha = models.DateTimeField(db_column='D_FECHA', blank=True, null=True)
    a_comentario = models.CharField(db_column='A_COMENTARIO', max_length=10000, blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'SGDP_VALOR_PARAMETRO_DE_TAREA'


class VinculacionExp(models.Model):
    id_vinculacion_exp = models.BigIntegerField(db_column='ID_VINCULACION_EXP', primary_key=True)
    id_instancia_de_proceso = models.ForeignKey(InstanciasDeProcesos, models.DO_NOTHING, db_column='ID_INSTANCIA_DE_PROCESO', related_name='vinculacion_procesos')
    id_instancia_de_proceso_antecesor = models.ForeignKey(InstanciasDeProcesos, models.DO_NOTHING, db_column='ID_INSTANCIA_DE_PROCESO_ANTECESOR',
                                                          related_name='vinculacion_procesos_anteriores')
    id_usuario = models.CharField(db_column='ID_USUARIO', max_length=30)
    d_fecha_vinculacion = models.DateTimeField(db_column='D_FECHA_VINCULACION')
    a_comentario = models.TextField(db_column='A_COMENTARIO')

    class Meta:
        managed = False
        db_table = 'SGDP_VINCULACION_EXP'
        unique_together = (('id_instancia_de_proceso', 'id_instancia_de_proceso_antecesor'),)


class Zona(models.Model):
    id = models.BigAutoField(db_column='ID_ZONA', primary_key=True)
    nombre = models.CharField(db_column='NOMBRE', max_length=255)

    class Meta:
        managed = True
        db_table = 'SGDP_ZONA'
        unique_together = (('nombre',),)
