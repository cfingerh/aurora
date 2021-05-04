--
-- PostgreSQL database dump
--

-- Dumped from database version 12.6 (Ubuntu 12.6-0ubuntu0.20.04.1)
-- Dumped by pg_dump version 12.6 (Ubuntu 12.6-0ubuntu0.20.04.1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: sgdp; Type: SCHEMA; Schema: -; Owner: sgdp
--

CREATE SCHEMA sgdp;


ALTER SCHEMA sgdp OWNER TO sgdp;

--
-- Name: levenshtein(text, text); Type: FUNCTION; Schema: public; Owner: sgdp
--

CREATE FUNCTION public.levenshtein(s text, t text) RETURNS integer
    LANGUAGE plpgsql IMMUTABLE
    AS $$
DECLARE i integer;
DECLARE j integer;
DECLARE m integer;
DECLARE n integer;
DECLARE d integer[];
DECLARE c integer;

BEGIN
        m := char_length(s);
        n := char_length(t);

        i := 0;
        j := 0;

        FOR i IN 0..m LOOP
               d[i*(n+1)] = i;
        END LOOP;

        FOR j IN 0..n LOOP
               d[j] = j;
        END LOOP;

        FOR i IN 1..m LOOP
               FOR j IN 1..n LOOP
                       IF SUBSTRING(s,i,1) = SUBSTRING(t, j,1) THEN
                               c := 0;
                       ELSE
                               c := 1;
                       END IF;
                       d[i*(n+1)+j] := LEAST(d[(i-1)*(n+1)+j]+1, d[i*(n+1)+j-1]+1, d[(i-1)*(n+1)+j-1]+c);
               END LOOP;
        END LOOP;

        return d[m*(n+1)+n];   
END;
$$;


ALTER FUNCTION public.levenshtein(s text, t text) OWNER TO sgdp;

--
-- Name: actualizaIdUnidadEnInstanciasDeProcesos(); Type: FUNCTION; Schema: sgdp; Owner: sgdp
--

CREATE FUNCTION sgdp."actualizaIdUnidadEnInstanciasDeProcesos"() RETURNS character varying
    LANGUAGE plpgsql
    AS $$
    DECLARE

        instancias_procesos_cursor CURSOR FOR 
                                    SELECT * 
																		FROM "SGDP_INSTANCIAS_DE_PROCESOS" WHERE "ID_UNIDAD" IS NULL;
																		
				registro_instancias_procesos record;								

        
				idUnidad INTEGER;
        
        idTareasInsertadas varchar;

    BEGIN   

   

    OPEN instancias_procesos_cursor;

    LOOP

        FETCH instancias_procesos_cursor INTO registro_instancias_procesos;
        EXIT WHEN NOT FOUND;
				
				SELECT "ID_UNIDAD" INTO idUnidad FROM "SGDP_PROCESOS" WHERE "ID_PROCESO" = registro_instancias_procesos."ID_PROCESO";

				UPDATE "SGDP_INSTANCIAS_DE_PROCESOS" SET "ID_UNIDAD" = idUnidad WHERE "ID_INSTANCIA_DE_PROCESO" = registro_instancias_procesos."ID_INSTANCIA_DE_PROCESO";

    END LOOP;    
    CLOSE instancias_procesos_cursor;

    RETURN 'OK';

    END;

$$;


ALTER FUNCTION sgdp."actualizaIdUnidadEnInstanciasDeProcesos"() OWNER TO sgdp;

--
-- Name: copiaProcesoVigentePorIdProceso(integer, integer); Type: FUNCTION; Schema: sgdp; Owner: sgdp
--

CREATE FUNCTION sgdp."copiaProcesoVigentePorIdProceso"(idproceso integer, idnuevaunidad integer) RETURNS character varying
    LANGUAGE plpgsql
    AS $_$
    DECLARE

        procesos_cursor CURSOR FOR 
                                    SELECT * 
																		FROM "SGDP_PROCESOS"
                                    WHERE "ID_PROCESO" = idproceso
                                    AND "B_VIGENTE" = TRUE;

        registro_proceso record;

        tareas_cursor refcursor;
        registro_tarea record;

        tipos_de_documentos_cursor refcursor;
        registro_tipos_de_documentos record; 

        documentos_de_salida_cursor refcursor; 
        registro_documentos_de_salida record;

        referencias_de_tarea_cursor refcursor; 
        registro_referencias_de_tarea record;   

        responsabilidad_cursor refcursor;
        registro_responsabilidad record;

        usuario_resp_cursor refcursor;
        registro_usuario_resp record;    

        seqIdProceso INTEGER;
        seqIdTarea INTEGER;
        seqIdTipoDeDocumento INTEGER;        
        idTareaReferencia INTEGER;
        seqIdReferenciasDeTareas INTEGER;
        seqIdResponsabilidad INTEGER;
        seqIdUsuarioResponsabilidad INTEGER;
				seqIdTareaSegundoLoop INTEGER;

        queryTarea varchar;
        queryTiposDeDocumentos varchar;
        queryDocumentosDeSalida varchar;
        queryReferenciasDeTareas varchar;
        idDiagramaTareaReferencia varchar;
        queryResponsabilidad varchar;
        queryUsuarioResponsabilidad varchar;

        idProcesosInsertados varchar;
        idTareasInsertadas varchar;

    BEGIN   

    idProcesosInsertados := '';
    idTareasInsertadas := '';

    OPEN procesos_cursor;

    LOOP

        FETCH procesos_cursor INTO registro_proceso;
        EXIT WHEN NOT FOUND;

        select nextval('"SEQ_ID_PROCESO"') into seqIdProceso;   

        idProcesosInsertados := CAST(seqIdProceso AS VARCHAR) || ',' || idProcesosInsertados;

        --START TRANSACTION;

        --insertar en la tabla de SGDP_PROCESOS usando seqIdProceso, registro_proceso e idNuevaUnidad
				INSERT INTO "SGDP_PROCESOS" VALUES (seqIdProceso, registro_proceso."A_NOMBRE_PROCESO", registro_proceso."A_DESCRIPCION_PROCESO", registro_proceso."ID_MACRO_PROCESO"
				,registro_proceso."B_VIGENTE", registro_proceso."N_DIAS_HABILES_MAX_DURACION", idNuevaUnidad, registro_proceso."B_CONFIDENCIAL", registro_proceso."X_BPMN"
				,registro_proceso."A_CODIGO_PROCESO", now());

        queryTarea := 'SELECT * FROM "SGDP_TAREAS" T WHERE T."ID_PROCESO" = $1';
				
				
				OPEN tareas_cursor FOR EXECUTE queryTarea USING registro_proceso."ID_PROCESO";        

        LOOP

            FETCH tareas_cursor INTO registro_tarea;
            EXIT WHEN NOT FOUND;
						
						SELECT nextval('"SEQ_ID_TAREA"') INTO seqIdTarea;

            idTareasInsertadas := CAST(seqIdTarea AS VARCHAR) || ',' || idTareasInsertadas;

            --insertar en la tabla de SGDP_TAREAS usando seqIdTarea, seqIdProceso y registro_tarea
						INSERT INTO "SGDP_TAREAS" VALUES (seqIdTarea, registro_tarea."A_NOMBRE_TAREA", registro_tarea."A_DESCRIPCION_TAREA", seqIdProceso
																							, registro_tarea."N_DIAS_HABILES_MAX_DURACION", registro_tarea."N_ORDEN", registro_tarea."B_VIGENTE", registro_tarea."B_SOLO_INFORMAR"
																							, registro_tarea."ID_ETAPA", registro_tarea."B_OBLIGATORIA", registro_tarea."B_ES_ULTIMA_TAREA", registro_tarea."A_TIPO_DE_BIFURCACION"
																							, registro_tarea."B_PUEDE_VISAR_DOCUMENTOS", registro_tarea."B_PUEDE_APLICAR_FEA", registro_tarea."A_URL_CONTROL", registro_tarea."ID_DIAGRAMA"
																							, registro_tarea."B_ASIGNA_NUM_DOC", registro_tarea."B_ESPERAR_RESP", registro_tarea."B_CONFORMA_EXPEDIENTE", registro_tarea."N_DIAS_RESETEO"
																							, registro_tarea."A_TIPO_RESETEO", registro_tarea."A_URL_WS", registro_tarea."B_DISTRIBUYE", registro_tarea."B_NUMERACION_AUTO");

            --COMMIT;

				
				END LOOP;
				CLOSE tareas_cursor;
 
        OPEN tareas_cursor FOR EXECUTE queryTarea USING registro_proceso."ID_PROCESO";        

        LOOP

            FETCH tareas_cursor INTO registro_tarea;
            EXIT WHEN NOT FOUND;
						
						SELECT "ID_TAREA" INTO seqIdTareaSegundoLoop FROM "SGDP_TAREAS" WHERE "ID_PROCESO" = seqIdProceso AND "ID_DIAGRAMA" = registro_tarea."ID_DIAGRAMA" AND "ID_TAREA" <> registro_tarea."ID_TAREA";
            
            queryTiposDeDocumentos := 'SELECT * FROM "SGDP_TIPOS_DE_DOCUMENTOS" D
                                    WHERE D."ID_TIPO_DE_DOCUMENTO" IN (
                                        SELECT DS."ID_TIPO_DE_DOCUMENTO" FROM "SGDP_DOCUMENTOS_DE_SALIDA_DE_TAREAS" DS
                                            WHERE DS."ID_TAREA" = $1
                                    )';
            
            OPEN tipos_de_documentos_cursor FOR EXECUTE queryTiposDeDocumentos USING registro_tarea."ID_TAREA";
            
            LOOP

                FETCH tipos_de_documentos_cursor INTO registro_tipos_de_documentos;
                EXIT WHEN NOT FOUND;

                SELECT nextval('"SEQ_ID_TIPO_DE_DOCUMENTO"') INTO seqIdTipoDeDocumento;

                --insertar en la tabla de SGDP_TIPOS_DE_DOCUMENTOS usando seqIdTipoDeDocumento y registro_tipos_de_documentos
								INSERT INTO "SGDP_TIPOS_DE_DOCUMENTOS" VALUES(seqIdTipoDeDocumento, registro_tipos_de_documentos."A_NOMBRE_DE_TIPO_DE_DOCUMENTO", registro_tipos_de_documentos."B_CONFORMA_EXPEDIENTE"
																														, registro_tipos_de_documentos."B_APLICA_VISACION", registro_tipos_de_documentos."B_APLICA_FEA"
																														, registro_tipos_de_documentos."B_ES_DOCUMENTO_CONDUCTOR", registro_tipos_de_documentos."ID_CATEGORIA_DE_TIPO_DE_DOCUMENTO"
																														, registro_tipos_de_documentos."B_NUMERACION_AUTO", registro_tipos_de_documentos."A_COD_TIPO_DOC" 
																														, registro_tipos_de_documentos."A_NOM_COMP_CAT_TIPO_DOC");

                queryDocumentosDeSalida := 'SELECT * FROM "SGDP_DOCUMENTOS_DE_SALIDA_DE_TAREAS" DS
                                            WHERE DS."ID_TAREA" = $1';

                OPEN documentos_de_salida_cursor FOR EXECUTE queryDocumentosDeSalida USING registro_tarea."ID_TAREA";

                LOOP

                    FETCH documentos_de_salida_cursor INTO registro_documentos_de_salida;
                    EXIT WHEN NOT FOUND;

                    --insertar en la tabla de SGDP_DOCUMENTOS_DE_SALIDA_DE_TAREAS usando seqIdTareaSegundoLoop, seqIdTipoDeDocumento y registro_documentos_de_salida
										INSERT INTO "SGDP_DOCUMENTOS_DE_SALIDA_DE_TAREAS" VALUES (seqIdTareaSegundoLoop, seqIdTipoDeDocumento, registro_documentos_de_salida."N_ORDEN");										

                END LOOP;
                CLOSE documentos_de_salida_cursor;

            END LOOP; 
            CLOSE tipos_de_documentos_cursor;

            queryReferenciasDeTareas := 'SELECT * FROM "SGDP_REFERENCIAS_DE_TAREAS" R
                                            WHERE R."ID_TAREA" = $1 '; 

            OPEN referencias_de_tarea_cursor FOR EXECUTE queryReferenciasDeTareas USING registro_tarea."ID_TAREA"; 

            LOOP

                FETCH referencias_de_tarea_cursor INTO registro_referencias_de_tarea;
                EXIT WHEN NOT FOUND;

                SELECT "ID_DIAGRAMA" INTO idDiagramaTareaReferencia FROM "SGDP_TAREAS" WHERE "ID_PROCESO" = registro_proceso."ID_PROCESO"  AND "ID_TAREA" = registro_referencias_de_tarea."ID_TAREA_SIGUIENTE";

                SELECT "ID_TAREA" INTO idTareaReferencia FROM "SGDP_TAREAS" WHERE "ID_PROCESO" = seqIdProceso AND "ID_DIAGRAMA" = idDiagramaTareaReferencia AND "ID_TAREA" <> registro_referencias_de_tarea.	"ID_TAREA_SIGUIENTE";

                SELECT nextval('"SEQ_ID_REFERENCIA_DE_TAREA"') INTO seqIdReferenciasDeTareas;

                --insertar en la tabla de SGDP_REFERENCIAS_DE_TAREAS usando seqIdReferenciasDeTareas, seqIdTareaSegundoLoop, registro_referencias_de_tarea
								INSERT INTO "SGDP_REFERENCIAS_DE_TAREAS" VALUES (seqIdReferenciasDeTareas, seqIdTareaSegundoLoop, idTareaReferencia);
								

            END LOOP; 
            CLOSE referencias_de_tarea_cursor; 

            queryResponsabilidad := 'SELECT * FROM "SGDP_RESPONSABILIDAD" G
                                    WHERE G."ID_RESPONSABILIDAD" IN (
                                    SELECT "ID_RESPONSABILIDAD" FROM "SGDP_RESPONSABILIDAD_TAREA" S
                                    WHERE S."ID_TAREA" = $1
                                    ) ';

            OPEN responsabilidad_cursor FOR EXECUTE queryResponsabilidad USING registro_tarea."ID_TAREA";

            LOOP

                FETCH responsabilidad_cursor INTO registro_responsabilidad;
                EXIT WHEN NOT FOUND;

                SELECT nextval('"SEQ_ID_RESPONSABILIDAD"') INTO seqIdResponsabilidad;

                --insertar en la tabla de SGDP_RESPONSABILIDAD usando seqIdResponsabilidad, y registro_responsabilidad.A_NOMBRE_RESPONSABILIDAD
								INSERT INTO "SGDP_RESPONSABILIDAD" VALUES(seqIdResponsabilidad, registro_responsabilidad."A_NOMBRE_RESPONSABILIDAD");

                --insertar en la tabla de SGDP_RESPONSABILIDAD_TAREA usando seqIdResponsabilidad, y seqIdTareaSegundoLoop
								INSERT INTO "SGDP_RESPONSABILIDAD_TAREA" VALUES (seqIdResponsabilidad, seqIdTareaSegundoLoop);

                queryUsuarioResponsabilidad := 'SELECT * FROM "SGDP_USUARIO_RESPONSABILIDAD" U
                                                WHERE U."ID_RESPONSABILIDAD" IN (
                                                SELECT S."ID_RESPONSABILIDAD" FROM "SGDP_RESPONSABILIDAD_TAREA" S
                                                WHERE S."ID_TAREA" = $1
                                                )'; 

                OPEN usuario_resp_cursor FOR EXECUTE queryUsuarioResponsabilidad USING registro_tarea."ID_TAREA";

                LOOP

                    FETCH usuario_resp_cursor INTO registro_usuario_resp;
                    EXIT WHEN NOT FOUND;

                    SELECT nextval('"SEQ_ID_USUARIO_RESPONSABILIDAD"') INTO seqIdUsuarioResponsabilidad;

                    --insertar en la tabla de SGDP_USUARIO_RESPONSABILIDAD usando seqIdUsuarioResponsabilidad, seqIdResponsabilidad, 
                    --registro_usuario_resp.ID_USUARIO, registro_usuario_resp.N_ORDEN, registro_usuario_resp.B_SUBROGANDO
										INSERT INTO "SGDP_USUARIO_RESPONSABILIDAD" VALUES (registro_usuario_resp."ID_USUARIO", seqIdResponsabilidad, seqIdUsuarioResponsabilidad, registro_usuario_resp."N_ORDEN", registro_usuario_resp."B_SUBROGANDO");

                END LOOP;
                CLOSE usuario_resp_cursor;

            END LOOP;  
            CLOSE responsabilidad_cursor;   

        END LOOP;
        CLOSE tareas_cursor;
				
				--update SGDP_PROCESOS con registro_proceso.ID_PROCESO A registro_proceso."B_VIGENTE" = FALSE
				--UPDATE "SGDP_PROCESOS" SET "B_VIGENTE" = FALSE WHERE "ID_PROCESO" = registro_proceso."ID_PROCESO"

    END LOOP;    
    CLOSE procesos_cursor;

    RAISE NOTICE 'idProcesosInsertados: %', idProcesosInsertados;
    RAISE NOTICE 'idTareasInsertadas: %', idTareasInsertadas;

    RETURN 'OK';

    END;

$_$;


ALTER FUNCTION sgdp."copiaProcesoVigentePorIdProceso"(idproceso integer, idnuevaunidad integer) OWNER TO sgdp;

--
-- Name: copiaProcesosVigentesPorUnidad(integer, integer); Type: FUNCTION; Schema: sgdp; Owner: sgdp
--

CREATE FUNCTION sgdp."copiaProcesosVigentesPorUnidad"(idunidad integer, idnuevaunidad integer) RETURNS character varying
    LANGUAGE plpgsql
    AS $_$
    DECLARE

        procesos_cursor CURSOR FOR 
                                    SELECT * 
																		FROM "SGDP_PROCESOS"
                                    WHERE "ID_UNIDAD" = idUnidad
                                    AND "B_VIGENTE" = TRUE;

        registro_proceso record;

        tareas_cursor refcursor;
        registro_tarea record;

        tipos_de_documentos_cursor refcursor;
        registro_tipos_de_documentos record; 

        documentos_de_salida_cursor refcursor; 
        registro_documentos_de_salida record;

        referencias_de_tarea_cursor refcursor; 
        registro_referencias_de_tarea record;   

        responsabilidad_cursor refcursor;
        registro_responsabilidad record;

        usuario_resp_cursor refcursor;
        registro_usuario_resp record;    

        seqIdProceso INTEGER;
        seqIdTarea INTEGER;
        seqIdTipoDeDocumento INTEGER;        
        idTareaReferencia INTEGER;
        seqIdReferenciasDeTareas INTEGER;
        seqIdResponsabilidad INTEGER;
        seqIdUsuarioResponsabilidad INTEGER;
				seqIdTareaSegundoLoop INTEGER;

        queryTarea varchar;
        queryTiposDeDocumentos varchar;
        queryDocumentosDeSalida varchar;
        queryReferenciasDeTareas varchar;
        idDiagramaTareaReferencia varchar;
        queryResponsabilidad varchar;
        queryUsuarioResponsabilidad varchar;

        idProcesosInsertados varchar;
        idTareasInsertadas varchar;

    BEGIN   

    idProcesosInsertados := '';
    idTareasInsertadas := '';

    OPEN procesos_cursor;

    LOOP

        FETCH procesos_cursor INTO registro_proceso;
        EXIT WHEN NOT FOUND;

        select nextval('"SEQ_ID_PROCESO"') into seqIdProceso;   

        idProcesosInsertados := CAST(seqIdProceso AS VARCHAR) || ',' || idProcesosInsertados;

        --START TRANSACTION;

        --insertar en la tabla de SGDP_PROCESOS usando seqIdProceso, registro_proceso e idNuevaUnidad
				INSERT INTO "SGDP_PROCESOS" VALUES (seqIdProceso, registro_proceso."A_NOMBRE_PROCESO", registro_proceso."A_DESCRIPCION_PROCESO", registro_proceso."ID_MACRO_PROCESO"
				,registro_proceso."B_VIGENTE", registro_proceso."N_DIAS_HABILES_MAX_DURACION", idNuevaUnidad, registro_proceso."B_CONFIDENCIAL", registro_proceso."X_BPMN"
				,registro_proceso."A_CODIGO_PROCESO", now());

        queryTarea := 'SELECT * FROM "SGDP_TAREAS" T WHERE T."ID_PROCESO" = $1';
				
				
				OPEN tareas_cursor FOR EXECUTE queryTarea USING registro_proceso."ID_PROCESO";        

        LOOP

            FETCH tareas_cursor INTO registro_tarea;
            EXIT WHEN NOT FOUND;
						
						SELECT nextval('"SEQ_ID_TAREA"') INTO seqIdTarea;

            idTareasInsertadas := CAST(seqIdTarea AS VARCHAR) || ',' || idTareasInsertadas;

            --insertar en la tabla de SGDP_TAREAS usando seqIdTarea, seqIdProceso y registro_tarea
						INSERT INTO "SGDP_TAREAS" VALUES (seqIdTarea, registro_tarea."A_NOMBRE_TAREA", registro_tarea."A_DESCRIPCION_TAREA", seqIdProceso
																							, registro_tarea."N_DIAS_HABILES_MAX_DURACION", registro_tarea."N_ORDEN", registro_tarea."B_VIGENTE", registro_tarea."B_SOLO_INFORMAR"
																							, registro_tarea."ID_ETAPA", registro_tarea."B_OBLIGATORIA", registro_tarea."B_ES_ULTIMA_TAREA", registro_tarea."A_TIPO_DE_BIFURCACION"
																							, registro_tarea."B_PUEDE_VISAR_DOCUMENTOS", registro_tarea."B_PUEDE_APLICAR_FEA", registro_tarea."A_URL_CONTROL", registro_tarea."ID_DIAGRAMA"
																							, registro_tarea."B_ASIGNA_NUM_DOC", registro_tarea."B_ESPERAR_RESP", registro_tarea."B_CONFORMA_EXPEDIENTE", registro_tarea."N_DIAS_RESETEO"
																							, registro_tarea."A_TIPO_RESETEO", registro_tarea."A_URL_WS", registro_tarea."B_DISTRIBUYE", registro_tarea."B_NUMERACION_AUTO");

            --COMMIT;

				
				END LOOP;
				CLOSE tareas_cursor;
 
        OPEN tareas_cursor FOR EXECUTE queryTarea USING registro_proceso."ID_PROCESO";        

        LOOP

            FETCH tareas_cursor INTO registro_tarea;
            EXIT WHEN NOT FOUND;
						
						SELECT "ID_TAREA" INTO seqIdTareaSegundoLoop FROM "SGDP_TAREAS" WHERE "ID_PROCESO" = seqIdProceso AND "ID_DIAGRAMA" = registro_tarea."ID_DIAGRAMA" AND "ID_TAREA" <> registro_tarea."ID_TAREA";
            
            queryTiposDeDocumentos := 'SELECT * FROM "SGDP_TIPOS_DE_DOCUMENTOS" D
                                    WHERE D."ID_TIPO_DE_DOCUMENTO" IN (
                                        SELECT DS."ID_TIPO_DE_DOCUMENTO" FROM "SGDP_DOCUMENTOS_DE_SALIDA_DE_TAREAS" DS
                                            WHERE DS."ID_TAREA" = $1
                                    )';
            
            OPEN tipos_de_documentos_cursor FOR EXECUTE queryTiposDeDocumentos USING registro_tarea."ID_TAREA";
            
            LOOP

                FETCH tipos_de_documentos_cursor INTO registro_tipos_de_documentos;
                EXIT WHEN NOT FOUND;

                SELECT nextval('"SEQ_ID_TIPO_DE_DOCUMENTO"') INTO seqIdTipoDeDocumento;

                --insertar en la tabla de SGDP_TIPOS_DE_DOCUMENTOS usando seqIdTipoDeDocumento y registro_tipos_de_documentos
								INSERT INTO "SGDP_TIPOS_DE_DOCUMENTOS" VALUES(seqIdTipoDeDocumento, registro_tipos_de_documentos."A_NOMBRE_DE_TIPO_DE_DOCUMENTO", registro_tipos_de_documentos."B_CONFORMA_EXPEDIENTE"
																														, registro_tipos_de_documentos."B_APLICA_VISACION", registro_tipos_de_documentos."B_APLICA_FEA"
																														, registro_tipos_de_documentos."B_ES_DOCUMENTO_CONDUCTOR", registro_tipos_de_documentos."ID_CATEGORIA_DE_TIPO_DE_DOCUMENTO"
																														, registro_tipos_de_documentos."B_NUMERACION_AUTO", registro_tipos_de_documentos."A_COD_TIPO_DOC" 
																														, registro_tipos_de_documentos."A_NOM_COMP_CAT_TIPO_DOC");

                queryDocumentosDeSalida := 'SELECT * FROM "SGDP_DOCUMENTOS_DE_SALIDA_DE_TAREAS" DS
                                            WHERE DS."ID_TAREA" = $1';

                OPEN documentos_de_salida_cursor FOR EXECUTE queryDocumentosDeSalida USING registro_tarea."ID_TAREA";

                LOOP

                    FETCH documentos_de_salida_cursor INTO registro_documentos_de_salida;
                    EXIT WHEN NOT FOUND;

                    --insertar en la tabla de SGDP_DOCUMENTOS_DE_SALIDA_DE_TAREAS usando seqIdTareaSegundoLoop, seqIdTipoDeDocumento y registro_documentos_de_salida
										INSERT INTO "SGDP_DOCUMENTOS_DE_SALIDA_DE_TAREAS" VALUES (seqIdTareaSegundoLoop, seqIdTipoDeDocumento, registro_documentos_de_salida."N_ORDEN");										

                END LOOP;
                CLOSE documentos_de_salida_cursor;

            END LOOP; 
            CLOSE tipos_de_documentos_cursor;

            queryReferenciasDeTareas := 'SELECT * FROM "SGDP_REFERENCIAS_DE_TAREAS" R
                                            WHERE R."ID_TAREA" = $1 '; 

            OPEN referencias_de_tarea_cursor FOR EXECUTE queryReferenciasDeTareas USING registro_tarea."ID_TAREA"; 

            LOOP

                FETCH referencias_de_tarea_cursor INTO registro_referencias_de_tarea;
                EXIT WHEN NOT FOUND;

                SELECT "ID_DIAGRAMA" INTO idDiagramaTareaReferencia FROM "SGDP_TAREAS" WHERE "ID_PROCESO" = registro_proceso."ID_PROCESO"  AND "ID_TAREA" = registro_referencias_de_tarea."ID_TAREA_SIGUIENTE";

                SELECT "ID_TAREA" INTO idTareaReferencia FROM "SGDP_TAREAS" WHERE "ID_PROCESO" = seqIdProceso AND "ID_DIAGRAMA" = idDiagramaTareaReferencia AND "ID_TAREA" <> registro_referencias_de_tarea.	"ID_TAREA_SIGUIENTE";

                SELECT nextval('"SEQ_ID_REFERENCIA_DE_TAREA"') INTO seqIdReferenciasDeTareas;

                --insertar en la tabla de SGDP_REFERENCIAS_DE_TAREAS usando seqIdReferenciasDeTareas, seqIdTareaSegundoLoop, registro_referencias_de_tarea
								INSERT INTO "SGDP_REFERENCIAS_DE_TAREAS" VALUES (seqIdReferenciasDeTareas, seqIdTareaSegundoLoop, idTareaReferencia);
								

            END LOOP; 
            CLOSE referencias_de_tarea_cursor; 

            queryResponsabilidad := 'SELECT * FROM "SGDP_RESPONSABILIDAD" G
                                    WHERE G."ID_RESPONSABILIDAD" IN (
                                    SELECT "ID_RESPONSABILIDAD" FROM "SGDP_RESPONSABILIDAD_TAREA" S
                                    WHERE S."ID_TAREA" = $1
                                    ) ';

            OPEN responsabilidad_cursor FOR EXECUTE queryResponsabilidad USING registro_tarea."ID_TAREA";

            LOOP

                FETCH responsabilidad_cursor INTO registro_responsabilidad;
                EXIT WHEN NOT FOUND;

                SELECT nextval('"SEQ_ID_RESPONSABILIDAD"') INTO seqIdResponsabilidad;

                --insertar en la tabla de SGDP_RESPONSABILIDAD usando seqIdResponsabilidad, y registro_responsabilidad.A_NOMBRE_RESPONSABILIDAD
								INSERT INTO "SGDP_RESPONSABILIDAD" VALUES(seqIdResponsabilidad, registro_responsabilidad."A_NOMBRE_RESPONSABILIDAD");

                --insertar en la tabla de SGDP_RESPONSABILIDAD_TAREA usando seqIdResponsabilidad, y seqIdTareaSegundoLoop
								INSERT INTO "SGDP_RESPONSABILIDAD_TAREA" VALUES (seqIdResponsabilidad, seqIdTareaSegundoLoop);

                queryUsuarioResponsabilidad := 'SELECT * FROM "SGDP_USUARIO_RESPONSABILIDAD" U
                                                WHERE U."ID_RESPONSABILIDAD" IN (
                                                SELECT S."ID_RESPONSABILIDAD" FROM "SGDP_RESPONSABILIDAD_TAREA" S
                                                WHERE S."ID_TAREA" = $1
                                                )'; 

                OPEN usuario_resp_cursor FOR EXECUTE queryUsuarioResponsabilidad USING registro_tarea."ID_TAREA";

                LOOP

                    FETCH usuario_resp_cursor INTO registro_usuario_resp;
                    EXIT WHEN NOT FOUND;

                    SELECT nextval('"SEQ_ID_USUARIO_RESPONSABILIDAD"') INTO seqIdUsuarioResponsabilidad;

                    --insertar en la tabla de SGDP_USUARIO_RESPONSABILIDAD usando seqIdUsuarioResponsabilidad, seqIdResponsabilidad, 
                    --registro_usuario_resp.ID_USUARIO, registro_usuario_resp.N_ORDEN, registro_usuario_resp.B_SUBROGANDO
										INSERT INTO "SGDP_USUARIO_RESPONSABILIDAD" VALUES (registro_usuario_resp."ID_USUARIO", seqIdResponsabilidad, seqIdUsuarioResponsabilidad, registro_usuario_resp."N_ORDEN", registro_usuario_resp."B_SUBROGANDO");

                END LOOP;
                CLOSE usuario_resp_cursor;

            END LOOP;  
            CLOSE responsabilidad_cursor;   

        END LOOP;
        CLOSE tareas_cursor;
				
				--update SGDP_PROCESOS con registro_proceso.ID_PROCESO A registro_proceso."B_VIGENTE" = FALSE
				--UPDATE "SGDP_PROCESOS" SET "B_VIGENTE" = FALSE WHERE "ID_PROCESO" = registro_proceso."ID_PROCESO"

    END LOOP;    
    CLOSE procesos_cursor;

    RAISE NOTICE 'idProcesosInsertados: %', idProcesosInsertados;
    RAISE NOTICE 'idTareasInsertadas: %', idTareasInsertadas;

    RETURN 'OK';

    END;

$_$;


ALTER FUNCTION sgdp."copiaProcesosVigentesPorUnidad"(idunidad integer, idnuevaunidad integer) OWNER TO sgdp;

--
-- Name: fecha_vencimiento(); Type: FUNCTION; Schema: sgdp; Owner: sgdp
--

CREATE FUNCTION sgdp.fecha_vencimiento() RETURNS character varying
    LANGUAGE plpgsql
    AS $$
    DECLARE

        instancias_procesos_cursor CURSOR FOR 
                                    SELECT * 
							        FROM "SGDP_INSTANCIAS_DE_PROCESOS" WHERE "D_FECHA_VENCIMIENTO" > TO_DATE('01-01-2020', 'dd-mm-yyyy')
											AND "D_FECHA_INICIO" <= TO_DATE('02-01-2020 10:30:00', 'dd-mm-yyyy HH:MI:SS');
                                    --AND  "ID_INSTANCIA_DE_PROCESO" = 14645;
																		
		registro_instancias_procesos record;	
        
		fechaVencimiento TIMESTAMP;
        
        nombreExp varchar;

        fechaVencimientoNueva TIMESTAMP;

        diaDeLaSemana INTEGER;

        --esFeriado BOOLEAN;

        cant INTEGER;
				
				cantSumarInicial INTEGER;
				
				textoInterval VARCHAR;

    BEGIN  

    diaDeLaSemana := 0;
    cant := 0;    

    OPEN instancias_procesos_cursor;

    LOOP

        FETCH instancias_procesos_cursor INTO registro_instancias_procesos;
        EXIT WHEN NOT FOUND;
				
								select count(*) into cantSumarInicial from "SGDP_FECHAS_FERIADOS" where "D_FECHA_FERIADO" <= registro_instancias_procesos."D_FECHA_VENCIMIENTO"
								and  date_part('isodow', "D_FECHA_FERIADO") NOT IN (6,7)
								and "D_FECHA_FERIADO" >= '2020-01-01';
								
								RAISE NOTICE 'cantSumarInicial  %' , cantSumarInicial;
								
								textoInterval := cantSumarInicial || ' DAY';

                fechaVencimientoNueva := registro_instancias_procesos."D_FECHA_VENCIMIENTO" + CAST(cantSumarInicial||' DAYS' AS Interval);                
                diaDeLaSemana := date_part('isodow', fechaVencimientoNueva);

                select count(*) INTO cant from "SGDP_FECHAS_FERIADOS" where "A_FECHA_FERIADO" = to_CHAR(fechaVencimientoNueva, 'dd-mm-yyyy');

                RAISE NOTICE 'diaDeLaSemana 1: %' , diaDeLaSemana;

                WHILE ( 
                        diaDeLaSemana = 6 
                        OR
                        diaDeLaSemana = 7
                        OR
                        cant > 0
                        )
                
                LOOP

                    fechaVencimientoNueva := fechaVencimientoNueva + INTERVAL '1 DAY';
                    select count(*) INTO cant from "SGDP_FECHAS_FERIADOS" where "A_FECHA_FERIADO" = to_CHAR(fechaVencimientoNueva, 'dd-mm-yyyy');
                    diaDeLaSemana := date_part('isodow', fechaVencimientoNueva);

                    RAISE NOTICE 'diaDeLaSemana 2: %' , diaDeLaSemana;
                    
                END LOOP ; 

                RAISE NOTICE 'EXPEDIENTE: % , FECHA_VENCIMIENTO: %, FECHA_VENCIMIENTO_NUEVA: %', registro_instancias_procesos."A_NOMBRE_EXPEDIENTE", registro_instancias_procesos."D_FECHA_VENCIMIENTO", fechaVencimientoNueva;                

                INSERT INTO "act_exp"("exp", "fecha_nueva", "fecha", "ID_INSTANCIA_DE_PROCESO") 
								VALUES (registro_instancias_procesos."A_NOMBRE_EXPEDIENTE", fechaVencimientoNueva, registro_instancias_procesos."D_FECHA_VENCIMIENTO", "registro_instancias_procesos"."ID_INSTANCIA_DE_PROCESO");
								
															
								UPDATE "SGDP_INSTANCIAS_DE_PROCESOS" 
								SET  "D_FECHA_VENCIMIENTO" = fechaVencimientoNueva 
								WHERE "ID_INSTANCIA_DE_PROCESO" = "registro_instancias_procesos"."ID_INSTANCIA_DE_PROCESO";


    END LOOP;    
    CLOSE instancias_procesos_cursor;

    RETURN 'OK';

    END;

$$;


ALTER FUNCTION sgdp.fecha_vencimiento() OWNER TO sgdp;

--
-- Name: fecha_vencimiento_tareas(); Type: FUNCTION; Schema: sgdp; Owner: sgdp
--

CREATE FUNCTION sgdp.fecha_vencimiento_tareas() RETURNS character varying
    LANGUAGE plpgsql
    AS $$
    DECLARE

        instancias_tareas_cursor CURSOR FOR 
                                    select * 
                                    from "SGDP_INSTANCIAS_DE_TAREAS" where "D_FECHA_VENCIMIENTO" > TO_DATE('01-01-2020', 'dd-mm-yyyy')
																		AND "D_FECHA_INICIO" <= TO_DATE('02-01-2020 10:30:00', 'dd-mm-yyyy HH:MI:SS');
																		
		registro_instancias_tareas record;	
        
		fechaVencimiento TIMESTAMP;
        
        nombreExp varchar;

        fechaVencimientoNueva TIMESTAMP;

        diaDeLaSemana INTEGER;

        --esFeriado BOOLEAN;

        cant INTEGER;
				
				cantSumarInicial INTEGER;
				
				textoInterval VARCHAR;

    BEGIN  

    diaDeLaSemana := 0;
    cant := 0;    

    OPEN instancias_tareas_cursor;

    LOOP

        FETCH instancias_tareas_cursor INTO registro_instancias_tareas;
        EXIT WHEN NOT FOUND;
				
								select count(*) into cantSumarInicial from "SGDP_FECHAS_FERIADOS" where "D_FECHA_FERIADO" <= registro_instancias_tareas.	"D_FECHA_VENCIMIENTO"
								and  date_part('isodow', "D_FECHA_FERIADO") NOT IN (6,7)
								and "D_FECHA_FERIADO" >= '2020-01-01';
								
								RAISE NOTICE 'cantSumarInicial  %' , cantSumarInicial;
								
								textoInterval := cantSumarInicial || ' DAY';

                fechaVencimientoNueva := registro_instancias_tareas."D_FECHA_VENCIMIENTO" + CAST(cantSumarInicial||' DAYS' AS Interval);              
                diaDeLaSemana := date_part('isodow', fechaVencimientoNueva);

                select count(*) INTO cant from "SGDP_FECHAS_FERIADOS" where "A_FECHA_FERIADO" = to_CHAR(fechaVencimientoNueva, 'dd-mm-yyyy');

                RAISE NOTICE 'diaDeLaSemana 1: %' , diaDeLaSemana;

                WHILE ( 
                        diaDeLaSemana = 6 
                        OR
                        diaDeLaSemana = 7
                        OR
                        cant > 0
                        )
                
                LOOP

                    fechaVencimientoNueva := fechaVencimientoNueva + INTERVAL '1 DAY';
                    select count(*) INTO cant from "SGDP_FECHAS_FERIADOS" where "A_FECHA_FERIADO" = to_CHAR(fechaVencimientoNueva, 'dd-mm-yyyy');
                    diaDeLaSemana := date_part('isodow', fechaVencimientoNueva);

                    RAISE NOTICE 'diaDeLaSemana 2: %' , diaDeLaSemana;
                    
                END LOOP ; 

                RAISE NOTICE 'ID_INSTANCIA_DE_TAREA: %, D_FECHA_VENCIMIENTO: %, fechaVencimientoNueva: %' , registro_instancias_tareas."ID_INSTANCIA_DE_TAREA", registro_instancias_tareas."D_FECHA_VENCIMIENTO", fechaVencimientoNueva;
         
                INSERT INTO "act_exp_inst_tarea"("ID_INSTANCIA_DE_TAREA", "fecha_nueva", "fecha") 
				VALUES ("registro_instancias_tareas"."ID_INSTANCIA_DE_TAREA", fechaVencimientoNueva, registro_instancias_tareas."D_FECHA_VENCIMIENTO");
																							
				UPDATE "SGDP_INSTANCIAS_DE_TAREAS" 
				SET  "D_FECHA_VENCIMIENTO" = fechaVencimientoNueva 
				WHERE "ID_INSTANCIA_DE_TAREA" = "registro_instancias_tareas"."ID_INSTANCIA_DE_TAREA";


    END LOOP;    
    CLOSE instancias_tareas_cursor;

    RETURN 'OK';

    END;

$$;


ALTER FUNCTION sgdp.fecha_vencimiento_tareas() OWNER TO sgdp;

--
-- Name: SEQ_ID_ACCESO; Type: SEQUENCE; Schema: sgdp; Owner: sgdp
--

CREATE SEQUENCE sgdp."SEQ_ID_ACCESO"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE sgdp."SEQ_ID_ACCESO" OWNER TO sgdp;

--
-- Name: SEQ_ID_ACCION_HISTORICO_INST_DE_TAREA; Type: SEQUENCE; Schema: sgdp; Owner: sgdp
--

CREATE SEQUENCE sgdp."SEQ_ID_ACCION_HISTORICO_INST_DE_TAREA"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE sgdp."SEQ_ID_ACCION_HISTORICO_INST_DE_TAREA" OWNER TO sgdp;

--
-- Name: SEQ_ID_ARCHIVOS_HIST_INST_DE_TAREAS; Type: SEQUENCE; Schema: sgdp; Owner: sgdp
--

CREATE SEQUENCE sgdp."SEQ_ID_ARCHIVOS_HIST_INST_DE_TAREAS"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE sgdp."SEQ_ID_ARCHIVOS_HIST_INST_DE_TAREAS" OWNER TO sgdp;

--
-- Name: SEQ_ID_ARCHIVOS_INST_DE_TAREA; Type: SEQUENCE; Schema: sgdp; Owner: sgdp
--

CREATE SEQUENCE sgdp."SEQ_ID_ARCHIVOS_INST_DE_TAREA"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE sgdp."SEQ_ID_ARCHIVOS_INST_DE_TAREA" OWNER TO sgdp;

--
-- Name: SEQ_ID_ARCHIVOS_INST_DE_TAREA_METADATA; Type: SEQUENCE; Schema: sgdp; Owner: sgdp
--

CREATE SEQUENCE sgdp."SEQ_ID_ARCHIVOS_INST_DE_TAREA_METADATA"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE sgdp."SEQ_ID_ARCHIVOS_INST_DE_TAREA_METADATA" OWNER TO sgdp;

--
-- Name: SEQ_ID_ASIGNACION_NUMERO_DOC; Type: SEQUENCE; Schema: sgdp; Owner: sgdp
--

CREATE SEQUENCE sgdp."SEQ_ID_ASIGNACION_NUMERO_DOC"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE sgdp."SEQ_ID_ASIGNACION_NUMERO_DOC" OWNER TO sgdp;

--
-- Name: SEQ_ID_AUTOR; Type: SEQUENCE; Schema: sgdp; Owner: sgdp
--

CREATE SEQUENCE sgdp."SEQ_ID_AUTOR"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE sgdp."SEQ_ID_AUTOR" OWNER TO sgdp;

--
-- Name: SEQ_ID_CARGA; Type: SEQUENCE; Schema: sgdp; Owner: sgdp
--

CREATE SEQUENCE sgdp."SEQ_ID_CARGA"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE sgdp."SEQ_ID_CARGA" OWNER TO sgdp;

--
-- Name: SEQ_ID_CARGO; Type: SEQUENCE; Schema: sgdp; Owner: sgdp
--

CREATE SEQUENCE sgdp."SEQ_ID_CARGO"
    START WITH 3
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE sgdp."SEQ_ID_CARGO" OWNER TO sgdp;

--
-- Name: SEQ_ID_CATEGORIA_DE_TIPO_DE_DOCUMENTO; Type: SEQUENCE; Schema: sgdp; Owner: sgdp
--

CREATE SEQUENCE sgdp."SEQ_ID_CATEGORIA_DE_TIPO_DE_DOCUMENTO"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE sgdp."SEQ_ID_CATEGORIA_DE_TIPO_DE_DOCUMENTO" OWNER TO sgdp;

--
-- Name: SEQ_ID_COMENT_HIST_INST_DE_TAREAS; Type: SEQUENCE; Schema: sgdp; Owner: sgdp
--

CREATE SEQUENCE sgdp."SEQ_ID_COMENT_HIST_INST_DE_TAREAS"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE sgdp."SEQ_ID_COMENT_HIST_INST_DE_TAREAS" OWNER TO sgdp;

--
-- Name: SEQ_ID_DETALLE_CARGA; Type: SEQUENCE; Schema: sgdp; Owner: sgdp
--

CREATE SEQUENCE sgdp."SEQ_ID_DETALLE_CARGA"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE sgdp."SEQ_ID_DETALLE_CARGA" OWNER TO sgdp;

--
-- Name: SEQ_ID_DOCUMENTO; Type: SEQUENCE; Schema: sgdp; Owner: sgdp
--

CREATE SEQUENCE sgdp."SEQ_ID_DOCUMENTO"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE sgdp."SEQ_ID_DOCUMENTO" OWNER TO sgdp;

--
-- Name: SEQ_ID_ESTADO_DE_PROCESO; Type: SEQUENCE; Schema: sgdp; Owner: sgdp
--

CREATE SEQUENCE sgdp."SEQ_ID_ESTADO_DE_PROCESO"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE sgdp."SEQ_ID_ESTADO_DE_PROCESO" OWNER TO sgdp;

--
-- Name: SEQ_ID_ESTADO_DE_TAREA; Type: SEQUENCE; Schema: sgdp; Owner: sgdp
--

CREATE SEQUENCE sgdp."SEQ_ID_ESTADO_DE_TAREA"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE sgdp."SEQ_ID_ESTADO_DE_TAREA" OWNER TO sgdp;

--
-- Name: SEQ_ID_ESTADO_SOLICITUD_CREACION_EXP; Type: SEQUENCE; Schema: sgdp; Owner: sgdp
--

CREATE SEQUENCE sgdp."SEQ_ID_ESTADO_SOLICITUD_CREACION_EXP"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE sgdp."SEQ_ID_ESTADO_SOLICITUD_CREACION_EXP" OWNER TO sgdp;

--
-- Name: SEQ_ID_ETAPA; Type: SEQUENCE; Schema: sgdp; Owner: sgdp
--

CREATE SEQUENCE sgdp."SEQ_ID_ETAPA"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE sgdp."SEQ_ID_ETAPA" OWNER TO sgdp;

--
-- Name: SEQ_ID_EXPEDIENTE; Type: SEQUENCE; Schema: sgdp; Owner: sgdp
--

CREATE SEQUENCE sgdp."SEQ_ID_EXPEDIENTE"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE sgdp."SEQ_ID_EXPEDIENTE" OWNER TO sgdp;

--
-- Name: SEQ_ID_HISTORICO_ARCHIVOS_INST_DE_TAREAS; Type: SEQUENCE; Schema: sgdp; Owner: sgdp
--

CREATE SEQUENCE sgdp."SEQ_ID_HISTORICO_ARCHIVOS_INST_DE_TAREAS"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE sgdp."SEQ_ID_HISTORICO_ARCHIVOS_INST_DE_TAREAS" OWNER TO sgdp;

--
-- Name: SEQ_ID_HISTORICO_DE_INST_DE_TAREA; Type: SEQUENCE; Schema: sgdp; Owner: sgdp
--

CREATE SEQUENCE sgdp."SEQ_ID_HISTORICO_DE_INST_DE_TAREA"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE sgdp."SEQ_ID_HISTORICO_DE_INST_DE_TAREA" OWNER TO sgdp;

--
-- Name: SEQ_ID_HISTORICO_FIRMA; Type: SEQUENCE; Schema: sgdp; Owner: sgdp
--

CREATE SEQUENCE sgdp."SEQ_ID_HISTORICO_FIRMA"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE sgdp."SEQ_ID_HISTORICO_FIRMA" OWNER TO sgdp;

--
-- Name: SEQ_ID_HISTORICO_SOLICITUD_CREACION_EXP; Type: SEQUENCE; Schema: sgdp; Owner: sgdp
--

CREATE SEQUENCE sgdp."SEQ_ID_HISTORICO_SOLICITUD_CREACION_EXP"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE sgdp."SEQ_ID_HISTORICO_SOLICITUD_CREACION_EXP" OWNER TO sgdp;

--
-- Name: SEQ_ID_HISTORICO_VALOR_PARAMETRO_DE_TAREA; Type: SEQUENCE; Schema: sgdp; Owner: sgdp
--

CREATE SEQUENCE sgdp."SEQ_ID_HISTORICO_VALOR_PARAMETRO_DE_TAREA"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE sgdp."SEQ_ID_HISTORICO_VALOR_PARAMETRO_DE_TAREA" OWNER TO sgdp;

--
-- Name: SEQ_ID_HISTORICO_VINCULACION_EXP; Type: SEQUENCE; Schema: sgdp; Owner: sgdp
--

CREATE SEQUENCE sgdp."SEQ_ID_HISTORICO_VINCULACION_EXP"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE sgdp."SEQ_ID_HISTORICO_VINCULACION_EXP" OWNER TO sgdp;

--
-- Name: SEQ_ID_HIST_FECHA_VENC_INS_PROC; Type: SEQUENCE; Schema: sgdp; Owner: sgdp
--

CREATE SEQUENCE sgdp."SEQ_ID_HIST_FECHA_VENC_INS_PROC"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE sgdp."SEQ_ID_HIST_FECHA_VENC_INS_PROC" OWNER TO sgdp;

--
-- Name: SEQ_ID_INSTANCIA_DE_PROCESO; Type: SEQUENCE; Schema: sgdp; Owner: sgdp
--

CREATE SEQUENCE sgdp."SEQ_ID_INSTANCIA_DE_PROCESO"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE sgdp."SEQ_ID_INSTANCIA_DE_PROCESO" OWNER TO sgdp;

--
-- Name: SEQ_ID_INSTANCIA_DE_TAREA; Type: SEQUENCE; Schema: sgdp; Owner: sgdp
--

CREATE SEQUENCE sgdp."SEQ_ID_INSTANCIA_DE_TAREA"
    START WITH 1000
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE sgdp."SEQ_ID_INSTANCIA_DE_TAREA" OWNER TO sgdp;

--
-- Name: SEQ_ID_INSTANCIA_DE_TAREA_LIBRE; Type: SEQUENCE; Schema: sgdp; Owner: sgdp
--

CREATE SEQUENCE sgdp."SEQ_ID_INSTANCIA_DE_TAREA_LIBRE"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE sgdp."SEQ_ID_INSTANCIA_DE_TAREA_LIBRE" OWNER TO sgdp;

--
-- Name: SEQ_ID_INSTANCIA_PROCESO_METADATA; Type: SEQUENCE; Schema: sgdp; Owner: sgdp
--

CREATE SEQUENCE sgdp."SEQ_ID_INSTANCIA_PROCESO_METADATA"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE sgdp."SEQ_ID_INSTANCIA_PROCESO_METADATA" OWNER TO sgdp;

--
-- Name: SEQ_ID_LISTA_DE_DISTRIBUCION; Type: SEQUENCE; Schema: sgdp; Owner: sgdp
--

CREATE SEQUENCE sgdp."SEQ_ID_LISTA_DE_DISTRIBUCION"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE sgdp."SEQ_ID_LISTA_DE_DISTRIBUCION" OWNER TO sgdp;

--
-- Name: SEQ_ID_LOG_CARGA; Type: SEQUENCE; Schema: sgdp; Owner: sgdp
--

CREATE SEQUENCE sgdp."SEQ_ID_LOG_CARGA"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE sgdp."SEQ_ID_LOG_CARGA" OWNER TO sgdp;

--
-- Name: SEQ_ID_LOG_ERROR; Type: SEQUENCE; Schema: sgdp; Owner: sgdp
--

CREATE SEQUENCE sgdp."SEQ_ID_LOG_ERROR"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE sgdp."SEQ_ID_LOG_ERROR" OWNER TO sgdp;

--
-- Name: SEQ_ID_LOG_FUERA_DE_OFICINA; Type: SEQUENCE; Schema: sgdp; Owner: sgdp
--

CREATE SEQUENCE sgdp."SEQ_ID_LOG_FUERA_DE_OFICINA"
    START WITH 2594
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE sgdp."SEQ_ID_LOG_FUERA_DE_OFICINA" OWNER TO sgdp;

--
-- Name: SEQ_ID_LOG_TRANSACCION; Type: SEQUENCE; Schema: sgdp; Owner: sgdp
--

CREATE SEQUENCE sgdp."SEQ_ID_LOG_TRANSACCION"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE sgdp."SEQ_ID_LOG_TRANSACCION" OWNER TO sgdp;

--
-- Name: SEQ_ID_MACRO_PROCESO; Type: SEQUENCE; Schema: sgdp; Owner: sgdp
--

CREATE SEQUENCE sgdp."SEQ_ID_MACRO_PROCESO"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE sgdp."SEQ_ID_MACRO_PROCESO" OWNER TO sgdp;

--
-- Name: SEQ_ID_PARAMETRO; Type: SEQUENCE; Schema: sgdp; Owner: sgdp
--

CREATE SEQUENCE sgdp."SEQ_ID_PARAMETRO"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE sgdp."SEQ_ID_PARAMETRO" OWNER TO sgdp;

--
-- Name: SEQ_ID_PARAMETRO_ARCHIVO_NACIONAL; Type: SEQUENCE; Schema: sgdp; Owner: sgdp
--

CREATE SEQUENCE sgdp."SEQ_ID_PARAMETRO_ARCHIVO_NACIONAL"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE sgdp."SEQ_ID_PARAMETRO_ARCHIVO_NACIONAL" OWNER TO sgdp;

--
-- Name: SEQ_ID_PARAMETRO_POR_CONTEXTO; Type: SEQUENCE; Schema: sgdp; Owner: sgdp
--

CREATE SEQUENCE sgdp."SEQ_ID_PARAMETRO_POR_CONTEXTO"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE sgdp."SEQ_ID_PARAMETRO_POR_CONTEXTO" OWNER TO sgdp;

--
-- Name: SEQ_ID_PARAM_TAREA; Type: SEQUENCE; Schema: sgdp; Owner: sgdp
--

CREATE SEQUENCE sgdp."SEQ_ID_PARAM_TAREA"
    START WITH 4
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE sgdp."SEQ_ID_PARAM_TAREA" OWNER TO sgdp;

--
-- Name: SEQ_ID_PERMISO; Type: SEQUENCE; Schema: sgdp; Owner: sgdp
--

CREATE SEQUENCE sgdp."SEQ_ID_PERMISO"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE sgdp."SEQ_ID_PERMISO" OWNER TO sgdp;

--
-- Name: SEQ_ID_PERSPECTIVA; Type: SEQUENCE; Schema: sgdp; Owner: sgdp
--

CREATE SEQUENCE sgdp."SEQ_ID_PERSPECTIVA"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE sgdp."SEQ_ID_PERSPECTIVA" OWNER TO sgdp;

--
-- Name: SEQ_ID_PROCESO; Type: SEQUENCE; Schema: sgdp; Owner: sgdp
--

CREATE SEQUENCE sgdp."SEQ_ID_PROCESO"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE sgdp."SEQ_ID_PROCESO" OWNER TO sgdp;

--
-- Name: SEQ_ID_PROCESO_FORM_CREA_EXP; Type: SEQUENCE; Schema: sgdp; Owner: sgdp
--

CREATE SEQUENCE sgdp."SEQ_ID_PROCESO_FORM_CREA_EXP"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE sgdp."SEQ_ID_PROCESO_FORM_CREA_EXP" OWNER TO sgdp;

--
-- Name: SEQ_ID_REFERENCIA_DE_TAREA; Type: SEQUENCE; Schema: sgdp; Owner: sgdp
--

CREATE SEQUENCE sgdp."SEQ_ID_REFERENCIA_DE_TAREA"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE sgdp."SEQ_ID_REFERENCIA_DE_TAREA" OWNER TO sgdp;

--
-- Name: SEQ_ID_RESPONSABILIDAD; Type: SEQUENCE; Schema: sgdp; Owner: sgdp
--

CREATE SEQUENCE sgdp."SEQ_ID_RESPONSABILIDAD"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE sgdp."SEQ_ID_RESPONSABILIDAD" OWNER TO sgdp;

--
-- Name: SEQ_ID_ROL; Type: SEQUENCE; Schema: sgdp; Owner: sgdp
--

CREATE SEQUENCE sgdp."SEQ_ID_ROL"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE sgdp."SEQ_ID_ROL" OWNER TO sgdp;

--
-- Name: SEQ_ID_SOLICITUD_CREACION_EXP; Type: SEQUENCE; Schema: sgdp; Owner: sgdp
--

CREATE SEQUENCE sgdp."SEQ_ID_SOLICITUD_CREACION_EXP"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE sgdp."SEQ_ID_SOLICITUD_CREACION_EXP" OWNER TO sgdp;

--
-- Name: SEQ_ID_TAREA; Type: SEQUENCE; Schema: sgdp; Owner: sgdp
--

CREATE SEQUENCE sgdp."SEQ_ID_TAREA"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE sgdp."SEQ_ID_TAREA" OWNER TO sgdp;

--
-- Name: SEQ_ID_TAREA_INICIA_PROCESO; Type: SEQUENCE; Schema: sgdp; Owner: sgdp
--

CREATE SEQUENCE sgdp."SEQ_ID_TAREA_INICIA_PROCESO"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE sgdp."SEQ_ID_TAREA_INICIA_PROCESO" OWNER TO sgdp;

--
-- Name: SEQ_ID_TEXTO_PARAMETRO_DE_TAREA; Type: SEQUENCE; Schema: sgdp; Owner: sgdp
--

CREATE SEQUENCE sgdp."SEQ_ID_TEXTO_PARAMETRO_DE_TAREA"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE sgdp."SEQ_ID_TEXTO_PARAMETRO_DE_TAREA" OWNER TO sgdp;

--
-- Name: SEQ_ID_TIPO; Type: SEQUENCE; Schema: sgdp; Owner: sgdp
--

CREATE SEQUENCE sgdp."SEQ_ID_TIPO"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE sgdp."SEQ_ID_TIPO" OWNER TO sgdp;

--
-- Name: SEQ_ID_TIPO_DE_DOCUMENTO; Type: SEQUENCE; Schema: sgdp; Owner: sgdp
--

CREATE SEQUENCE sgdp."SEQ_ID_TIPO_DE_DOCUMENTO"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE sgdp."SEQ_ID_TIPO_DE_DOCUMENTO" OWNER TO sgdp;

--
-- Name: SEQ_ID_TIPO_DE_TAREA_LIBRE; Type: SEQUENCE; Schema: sgdp; Owner: sgdp
--

CREATE SEQUENCE sgdp."SEQ_ID_TIPO_DE_TAREA_LIBRE"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE sgdp."SEQ_ID_TIPO_DE_TAREA_LIBRE" OWNER TO sgdp;

--
-- Name: SEQ_ID_TIPO_PARAMETRO_DE_TAREA; Type: SEQUENCE; Schema: sgdp; Owner: sgdp
--

CREATE SEQUENCE sgdp."SEQ_ID_TIPO_PARAMETRO_DE_TAREA"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE sgdp."SEQ_ID_TIPO_PARAMETRO_DE_TAREA" OWNER TO sgdp;

--
-- Name: SEQ_ID_UNIDAD; Type: SEQUENCE; Schema: sgdp; Owner: sgdp
--

CREATE SEQUENCE sgdp."SEQ_ID_UNIDAD"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE sgdp."SEQ_ID_UNIDAD" OWNER TO sgdp;

--
-- Name: SEQ_ID_USUARIO_RESPONSABILIDAD; Type: SEQUENCE; Schema: sgdp; Owner: sgdp
--

CREATE SEQUENCE sgdp."SEQ_ID_USUARIO_RESPONSABILIDAD"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE sgdp."SEQ_ID_USUARIO_RESPONSABILIDAD" OWNER TO sgdp;

--
-- Name: SEQ_ID_USUARIO_ROL; Type: SEQUENCE; Schema: sgdp; Owner: sgdp
--

CREATE SEQUENCE sgdp."SEQ_ID_USUARIO_ROL"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE sgdp."SEQ_ID_USUARIO_ROL" OWNER TO sgdp;

--
-- Name: SEQ_ID_VALOR_PARAMETRO_DE_TAREA; Type: SEQUENCE; Schema: sgdp; Owner: sgdp
--

CREATE SEQUENCE sgdp."SEQ_ID_VALOR_PARAMETRO_DE_TAREA"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE sgdp."SEQ_ID_VALOR_PARAMETRO_DE_TAREA" OWNER TO sgdp;

--
-- Name: SEQ_ID_VINCULACION_EXP; Type: SEQUENCE; Schema: sgdp; Owner: sgdp
--

CREATE SEQUENCE sgdp."SEQ_ID_VINCULACION_EXP"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE sgdp."SEQ_ID_VINCULACION_EXP" OWNER TO sgdp;

--
-- Name: SEQ_NOMBRE_ID_EXPEDIENTE; Type: SEQUENCE; Schema: sgdp; Owner: sgdp
--

CREATE SEQUENCE sgdp."SEQ_NOMBRE_ID_EXPEDIENTE"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE sgdp."SEQ_NOMBRE_ID_EXPEDIENTE" OWNER TO sgdp;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: SGDP_ACCESOS; Type: TABLE; Schema: sgdp; Owner: sgdp
--

CREATE TABLE sgdp."SGDP_ACCESOS" (
    "ID_ACCESO" bigint DEFAULT nextval('sgdp."SEQ_ID_ACCESO"'::regclass) NOT NULL,
    "A_NOMBRE_ACCESO" character varying(20),
    "A_VALOR_ACCESO_CHAR" character varying(100),
    "D_FECHA_CREACION" timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE sgdp."SGDP_ACCESOS" OWNER TO sgdp;

--
-- Name: SGDP_ACCIONES_HIST_INST_DE_TAREAS; Type: TABLE; Schema: sgdp; Owner: sgdp
--

CREATE TABLE sgdp."SGDP_ACCIONES_HIST_INST_DE_TAREAS" (
    "ID_ACCION_HISTORICO_INST_DE_TAREA" bigint NOT NULL,
    "A_NOMBRE_ACCION" character varying(30) NOT NULL,
    "A_DESC_ACCION" character varying(255)
);


ALTER TABLE sgdp."SGDP_ACCIONES_HIST_INST_DE_TAREAS" OWNER TO sgdp;

--
-- Name: SGDP_ARCHIVOS_INST_DE_TAREA; Type: TABLE; Schema: sgdp; Owner: sgdp
--

CREATE TABLE sgdp."SGDP_ARCHIVOS_INST_DE_TAREA" (
    "ID_ARCHIVOS_INST_DE_TAREA" bigint NOT NULL,
    "ID_INSTANCIA_DE_TAREA" bigint NOT NULL,
    "A_NOMBRE_ARCHIVO" character varying(1000) NOT NULL,
    "A_MIME_TYPE" character varying(100),
    "ID_ARCHIVO_CMS" character varying(100) NOT NULL,
    "A_VERSION" character varying(100) NOT NULL,
    "ID_TIPO_DE_DOCUMENTO" bigint,
    "ID_USUARIO" character varying(30),
    "D_FECHA_SUBIDO" timestamp(6) without time zone,
    "B_ESTA_VISADO" boolean,
    "B_ESTA_FIRMADO_CON_FEA_WEB_START" boolean,
    "B_ESTA_FIRMADO_CON_FEA_CENTRALIZADA" boolean,
    "D_FECHA_DOCUMENTO" timestamp(6) without time zone,
    "D_FECHA_RECEPCION" timestamp(6) without time zone,
    "ID_ARCHIVOS_INST_DE_TAREA_METADATA" bigint
);


ALTER TABLE sgdp."SGDP_ARCHIVOS_INST_DE_TAREA" OWNER TO sgdp;

--
-- Name: SGDP_ARCHIVOS_INST_DE_TAREA_METADATA; Type: TABLE; Schema: sgdp; Owner: sgdp
--

CREATE TABLE sgdp."SGDP_ARCHIVOS_INST_DE_TAREA_METADATA" (
    "ID_ARCHIVOS_INST_DE_TAREA_METADATA" bigint DEFAULT nextval('sgdp."SEQ_ID_ARCHIVOS_INST_DE_TAREA_METADATA"'::regclass) NOT NULL,
    "ID_TIPO" bigint,
    "A_TITULO" character varying(200),
    "A_AUTOR" character varying(200),
    "A_DESTINATARIOS" character varying(1000),
    "B_DIGITALIZADO" boolean,
    "D_FECHA_DOCUMENTO" timestamp without time zone,
    "A_NOMBRE_INTERESADO" character varying(200),
    "A_APELLIDO_PATERNO" character varying(200),
    "A_APELLIDO_MATERNO" character varying(200),
    "A_RUT" character varying(20),
    "A_ETIQUETAS" character varying(1000),
    "A_REGION" character varying(200),
    "A_COMUNA" character varying(200),
    "A_METADATA_CUSTOM" text,
    "N_FLAG_ENVIO" bigint
);


ALTER TABLE sgdp."SGDP_ARCHIVOS_INST_DE_TAREA_METADATA" OWNER TO sgdp;

--
-- Name: SGDP_ASIGNACIONES_NUMEROS_DOC; Type: TABLE; Schema: sgdp; Owner: sgdp
--

CREATE TABLE sgdp."SGDP_ASIGNACIONES_NUMEROS_DOC" (
    "ID_ASIGNACION_NUMERO_DOC" bigint NOT NULL,
    "N_NUMERO_DOCUMENTO" bigint NOT NULL,
    "ID_TIPO_DE_DOCUMENTO" bigint NOT NULL,
    "A_ESTADO" character varying(255),
    "D_ANIO" character varying(255) NOT NULL,
    "D_FECHA_CREACION" timestamp(6) without time zone NOT NULL,
    "D_FECHA_MODIFICACION" timestamp(6) without time zone
);


ALTER TABLE sgdp."SGDP_ASIGNACIONES_NUMEROS_DOC" OWNER TO sgdp;

--
-- Name: SGDP_AUTORES; Type: TABLE; Schema: sgdp; Owner: sgdp
--

CREATE TABLE sgdp."SGDP_AUTORES" (
    "ID_AUTOR" bigint DEFAULT nextval('sgdp."SEQ_ID_AUTOR"'::regclass) NOT NULL,
    "A_NOMBRE_AUTOR" character varying(100) NOT NULL
);


ALTER TABLE sgdp."SGDP_AUTORES" OWNER TO sgdp;

--
-- Name: SGDP_CARGAS; Type: TABLE; Schema: sgdp; Owner: sgdp
--

CREATE TABLE sgdp."SGDP_CARGAS" (
    "ID_CARGA" bigint DEFAULT nextval('sgdp."SEQ_ID_CARGA"'::regclass) NOT NULL,
    "N_CANTIDAD_DOCUMENTOS" bigint NOT NULL,
    "A_NOMBRE_SERIE" character varying(200),
    "A_NOMBRE_ACUERDO" character varying(200),
    "A_TIPO_ACUERDO" character varying(200),
    "A_ID_TRANSFERENCIA" character varying(500),
    "D_FECHA_CREACION" timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE sgdp."SGDP_CARGAS" OWNER TO sgdp;

--
-- Name: SGDP_CARGO; Type: TABLE; Schema: sgdp; Owner: sgdp
--

CREATE TABLE sgdp."SGDP_CARGO" (
    "ID_CARGO" bigint NOT NULL,
    "A_NOMBRE_CARGO" character varying(255) NOT NULL
);


ALTER TABLE sgdp."SGDP_CARGO" OWNER TO sgdp;

--
-- Name: SGDP_CARGO_RESPONSABILIDAD; Type: TABLE; Schema: sgdp; Owner: sgdp
--

CREATE TABLE sgdp."SGDP_CARGO_RESPONSABILIDAD" (
    "ID_CARGO" bigint NOT NULL,
    "ID_RESPONSABILIDAD" bigint NOT NULL
);


ALTER TABLE sgdp."SGDP_CARGO_RESPONSABILIDAD" OWNER TO sgdp;

--
-- Name: SGDP_CARGO_USUARIO_ROL; Type: TABLE; Schema: sgdp; Owner: sgdp
--

CREATE TABLE sgdp."SGDP_CARGO_USUARIO_ROL" (
    "ID_CARGO" bigint NOT NULL,
    "ID_USUARIO_ROL" bigint NOT NULL
);


ALTER TABLE sgdp."SGDP_CARGO_USUARIO_ROL" OWNER TO sgdp;

--
-- Name: SGDP_CATEGORIA_DE_TIPO_DE_DOCUMENTO; Type: TABLE; Schema: sgdp; Owner: sgdp
--

CREATE TABLE sgdp."SGDP_CATEGORIA_DE_TIPO_DE_DOCUMENTO" (
    "ID_CATEGORIA_DE_TIPO_DE_DOCUMENTO" bigint DEFAULT nextval('sgdp."SEQ_ID_CATEGORIA_DE_TIPO_DE_DOCUMENTO"'::regclass) NOT NULL,
    "A_NOMBRE_DE_CATEGORIA_DE_TIPO_DE_DOCUMENTO" text NOT NULL
);


ALTER TABLE sgdp."SGDP_CATEGORIA_DE_TIPO_DE_DOCUMENTO" OWNER TO sgdp;

--
-- Name: SGDP_DETALLES_CARGA; Type: TABLE; Schema: sgdp; Owner: sgdp
--

CREATE TABLE sgdp."SGDP_DETALLES_CARGA" (
    "ID_DETALLE_CARGA" bigint DEFAULT nextval('sgdp."SEQ_ID_DETALLE_CARGA"'::regclass) NOT NULL,
    "ID_CARGA" bigint NOT NULL,
    "A_NOMBRE_DOCUMENTO" character varying(200),
    "A_ID_ARCHIVO_CMS" character varying(200),
    "D_FECHA_CREACION" timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE sgdp."SGDP_DETALLES_CARGA" OWNER TO sgdp;

--
-- Name: SGDP_DOCUMENTOS_DE_SALIDA_DE_TAREAS; Type: TABLE; Schema: sgdp; Owner: sgdp
--

CREATE TABLE sgdp."SGDP_DOCUMENTOS_DE_SALIDA_DE_TAREAS" (
    "ID_TAREA" bigint NOT NULL,
    "ID_TIPO_DE_DOCUMENTO" bigint NOT NULL,
    "N_ORDEN" integer
);


ALTER TABLE sgdp."SGDP_DOCUMENTOS_DE_SALIDA_DE_TAREAS" OWNER TO sgdp;

--
-- Name: SGDP_ESTADOS_DE_PROCESOS; Type: TABLE; Schema: sgdp; Owner: sgdp
--

CREATE TABLE sgdp."SGDP_ESTADOS_DE_PROCESOS" (
    "ID_ESTADO_DE_PROCESO" bigint DEFAULT nextval('sgdp."SEQ_ID_ESTADO_DE_PROCESO"'::regclass) NOT NULL,
    "N_CODIGO_ESTADO_DE_PROCESO" integer NOT NULL,
    "A_NOMBRE_ESTADO_DE_PROCESO" character varying(30)
);


ALTER TABLE sgdp."SGDP_ESTADOS_DE_PROCESOS" OWNER TO sgdp;

--
-- Name: SGDP_ESTADOS_DE_TAREAS; Type: TABLE; Schema: sgdp; Owner: sgdp
--

CREATE TABLE sgdp."SGDP_ESTADOS_DE_TAREAS" (
    "ID_ESTADO_DE_TAREA" bigint DEFAULT nextval('sgdp."SEQ_ID_ESTADO_DE_TAREA"'::regclass) NOT NULL,
    "N_CODIGO_ESTADO_DE_TAREA" integer NOT NULL,
    "A_NOMBRE_ESTADO_DE_TAREA" character varying(20) NOT NULL
);


ALTER TABLE sgdp."SGDP_ESTADOS_DE_TAREAS" OWNER TO sgdp;

--
-- Name: SGDP_ESTADO_SOLICITUD_CREACION_EXP; Type: TABLE; Schema: sgdp; Owner: sgdp
--

CREATE TABLE sgdp."SGDP_ESTADO_SOLICITUD_CREACION_EXP" (
    "ID_ESTADO_SOLICITUD_CREACION_EXP" bigint DEFAULT nextval('sgdp."SEQ_ID_ESTADO_SOLICITUD_CREACION_EXP"'::regclass) NOT NULL,
    "A_NOMBRE_ESTADO_SOLICITUD_CREACION_EXP" character varying(20) NOT NULL
);


ALTER TABLE sgdp."SGDP_ESTADO_SOLICITUD_CREACION_EXP" OWNER TO sgdp;

--
-- Name: SGDP_ETAPAS; Type: TABLE; Schema: sgdp; Owner: sgdp
--

CREATE TABLE sgdp."SGDP_ETAPAS" (
    "ID_ETAPA" bigint DEFAULT nextval('sgdp."SEQ_ID_ETAPA"'::regclass) NOT NULL,
    "A_NOMBRE_ETAPA" character varying(30) NOT NULL
);


ALTER TABLE sgdp."SGDP_ETAPAS" OWNER TO sgdp;

--
-- Name: SGDP_FECHAS_FERIADOS; Type: TABLE; Schema: sgdp; Owner: sgdp
--

CREATE TABLE sgdp."SGDP_FECHAS_FERIADOS" (
    "A_FECHA_FERIADO" character(10) NOT NULL,
    "D_FECHA_FERIADO" timestamp(6) without time zone
);


ALTER TABLE sgdp."SGDP_FECHAS_FERIADOS" OWNER TO sgdp;

--
-- Name: SGDP_HISTORIAL_SEGUIMIENTO_IN_ID_HISTORICO_INSTANCIA_PROCES_seq; Type: SEQUENCE; Schema: sgdp; Owner: sgdp
--

CREATE SEQUENCE sgdp."SGDP_HISTORIAL_SEGUIMIENTO_IN_ID_HISTORICO_INSTANCIA_PROCES_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE sgdp."SGDP_HISTORIAL_SEGUIMIENTO_IN_ID_HISTORICO_INSTANCIA_PROCES_seq" OWNER TO sgdp;

--
-- Name: SGDP_HISTORICO_ACCIONES_INST_DE_TAREAS; Type: TABLE; Schema: sgdp; Owner: sgdp
--

CREATE TABLE sgdp."SGDP_HISTORICO_ACCIONES_INST_DE_TAREAS" (
    "ID_HISTORICO_ACCIONES_INST_DE_TAREAS" bigint NOT NULL,
    "A_NOMBRE_ACCION" character varying(30) NOT NULL
);


ALTER TABLE sgdp."SGDP_HISTORICO_ACCIONES_INST_DE_TAREAS" OWNER TO sgdp;

--
-- Name: SGDP_HISTORICO_ARCHIVOS_INST_DE_TAREAS; Type: TABLE; Schema: sgdp; Owner: sgdp
--

CREATE TABLE sgdp."SGDP_HISTORICO_ARCHIVOS_INST_DE_TAREAS" (
    "ID_HISTORICO_DE_INST_DE_TAREA" bigint NOT NULL,
    "A_NOMBRE_ARCHIVO" character varying(1000) NOT NULL,
    "A_MIME_TYPE" character varying(100),
    "ID_ARCHIVO_CMS" character varying(100) NOT NULL,
    "A_VERSION" character varying(100) NOT NULL,
    "ID_HISTORICO_ARCHIVOS_INST_DE_TAREAS" bigint NOT NULL,
    "ID_TIPO_DE_DOCUMENTO" bigint,
    "ID_USUARIO" character varying(30),
    "D_FECHA_DOCUMENTO" timestamp(6) without time zone,
    "D_FECHA_RECEPCION" timestamp(6) without time zone,
    "D_FECHA_SUBIDO" timestamp(6) without time zone
);


ALTER TABLE sgdp."SGDP_HISTORICO_ARCHIVOS_INST_DE_TAREAS" OWNER TO sgdp;

--
-- Name: SGDP_HISTORICO_DE_INST_DE_TAREAS; Type: TABLE; Schema: sgdp; Owner: sgdp
--

CREATE TABLE sgdp."SGDP_HISTORICO_DE_INST_DE_TAREAS" (
    "ID_HISTORICO_DE_INST_DE_TAREA" bigint NOT NULL,
    "ID_INSTANCIA_DE_TAREA_DE_ORIGEN" bigint NOT NULL,
    "D_FECHA_MOVIMIENTO" timestamp(6) without time zone NOT NULL,
    "ID_ACCION_HISTORICO_INST_DE_TAREA" bigint NOT NULL,
    "ID_USUARIO_ORIGEN" character varying(30) NOT NULL,
    "ID_INSTANCIA_DE_TAREA_DESTINO" bigint NOT NULL,
    "A_COMENTARIO" text,
    "A_MENSAJE_EXCEPCION" text,
    "N_DIAS_OCUPADOS" smallint,
    "N_MINUTOS_OCUPADOS" smallint,
    "N_HORAS_OCUPADAS" smallint
);


ALTER TABLE sgdp."SGDP_HISTORICO_DE_INST_DE_TAREAS" OWNER TO sgdp;

--
-- Name: SGDP_HISTORICO_FECHA_VENC_INS_PROC; Type: TABLE; Schema: sgdp; Owner: sgdp
--

CREATE TABLE sgdp."SGDP_HISTORICO_FECHA_VENC_INS_PROC" (
    "ID_HIST_FECHA_VENC_INS_PROC" bigint NOT NULL,
    "ID_INSTANCIA_DE_TAREA" bigint NOT NULL,
    "D_FECHA_VENCIMIENTO" timestamp(6) without time zone NOT NULL,
    "ID_USUARIO" character varying(30) NOT NULL
);


ALTER TABLE sgdp."SGDP_HISTORICO_FECHA_VENC_INS_PROC" OWNER TO sgdp;

--
-- Name: SGDP_HISTORICO_FIRMAS; Type: TABLE; Schema: sgdp; Owner: sgdp
--

CREATE TABLE sgdp."SGDP_HISTORICO_FIRMAS" (
    "ID_HISTORICO_FIRMA" bigint NOT NULL,
    "ID_INSTANCIA_DE_TAREA" bigint NOT NULL,
    "ID_ARCHIVO_CMS" character varying(100) NOT NULL,
    "ID_USUARIO" character varying(30) NOT NULL,
    "D_FECHA_FIRMA" timestamp(6) without time zone NOT NULL,
    "A_TIPO_FIRMA" character varying(100) NOT NULL,
    "ID_TIPO_DE_DOCUMENTO" bigint NOT NULL
);


ALTER TABLE sgdp."SGDP_HISTORICO_FIRMAS" OWNER TO sgdp;

--
-- Name: SGDP_HISTORICO_SEGUIMIENTO_INTANCIA_PROCESOS; Type: TABLE; Schema: sgdp; Owner: sgdp
--

CREATE TABLE sgdp."SGDP_HISTORICO_SEGUIMIENTO_INTANCIA_PROCESOS" (
    "ID_HISTORICO_INSTANCIA_PROCESO" bigint DEFAULT nextval('sgdp."SGDP_HISTORIAL_SEGUIMIENTO_IN_ID_HISTORICO_INSTANCIA_PROCES_seq"'::regclass) NOT NULL,
    "ID_INSTANCIA_PROCESO" bigint,
    "ID_USUARIO" character varying(255),
    "ID_USUARIO_ACCION" character varying(255),
    "A_ACCION" character varying(255),
    "D_FECHA_ACCION" timestamp(6) without time zone,
    "A_TIPO_DE_NOTIFICACION" character varying(255)
);


ALTER TABLE sgdp."SGDP_HISTORICO_SEGUIMIENTO_INTANCIA_PROCESOS" OWNER TO sgdp;

--
-- Name: SGDP_HISTORICO_SOLICITUD_CREACION_EXP; Type: TABLE; Schema: sgdp; Owner: sgdp
--

CREATE TABLE sgdp."SGDP_HISTORICO_SOLICITUD_CREACION_EXP" (
    "ID_HISTORICO_SOLICITUD_CREACION_EXP" bigint DEFAULT nextval('sgdp."SEQ_ID_HISTORICO_SOLICITUD_CREACION_EXP"'::regclass) NOT NULL,
    "ID_SOLICITUD_CREACION_EXP" bigint NOT NULL,
    "ID_INSTANCIA_DE_PROCESO" bigint,
    "ID_USUARIO_SOLICITANTE" character varying(30) NOT NULL,
    "ID_USUARIO_CREADOR_EXPEDIENTE" character varying(30),
    "ID_USUARIO_DESTINATARIO" character varying(30),
    "D_FECHA_SOLICITUD" timestamp(6) without time zone NOT NULL,
    "D_FECHA_ATENCION" timestamp(6) without time zone,
    "A_COMENTARIO" text,
    "ID_ESTADO_SOLICITUD_CREACION_EXP" bigint NOT NULL,
    "ID_PROCESO" bigint,
    "A_ASUNTO_MATERIA" character varying(1000) NOT NULL,
    "ID_AUTOR" bigint,
    "ID_USUARIO" character varying(30) NOT NULL,
    "D_FECHA" timestamp(6) without time zone NOT NULL,
    "A_TIPO_ACCION" character varying(100) NOT NULL
);


ALTER TABLE sgdp."SGDP_HISTORICO_SOLICITUD_CREACION_EXP" OWNER TO sgdp;

--
-- Name: SGDP_HISTORICO_USUARIOS_ASIGNADOS_A_TAREAS; Type: TABLE; Schema: sgdp; Owner: sgdp
--

CREATE TABLE sgdp."SGDP_HISTORICO_USUARIOS_ASIGNADOS_A_TAREAS" (
    "ID_HISTORICO_DE_INST_DE_TAREA" bigint NOT NULL,
    "ID_USUARIO" character varying(100) NOT NULL
);


ALTER TABLE sgdp."SGDP_HISTORICO_USUARIOS_ASIGNADOS_A_TAREAS" OWNER TO sgdp;

--
-- Name: SGDP_HISTORICO_VALOR_PARAMETRO_DE_TAREA; Type: TABLE; Schema: sgdp; Owner: sgdp
--

CREATE TABLE sgdp."SGDP_HISTORICO_VALOR_PARAMETRO_DE_TAREA" (
    "ID_HISTORICO_VALOR_PARAMETRO_DE_TAREA" bigint DEFAULT nextval('sgdp."SEQ_ID_HISTORICO_VALOR_PARAMETRO_DE_TAREA"'::regclass) NOT NULL,
    "ID_PARAM_TAREA" bigint NOT NULL,
    "A_VALOR" character varying(5000),
    "A_COMENTARIO" character varying(10000),
    "ID_HISTORICO_DE_INST_DE_TAREA" bigint NOT NULL
);


ALTER TABLE sgdp."SGDP_HISTORICO_VALOR_PARAMETRO_DE_TAREA" OWNER TO sgdp;

--
-- Name: SGDP_HISTORICO_VINCULACION_EXP; Type: TABLE; Schema: sgdp; Owner: sgdp
--

CREATE TABLE sgdp."SGDP_HISTORICO_VINCULACION_EXP" (
    "ID_HISTORICO_VINCULACION_EXP" bigint NOT NULL,
    "ID_INSTANCIA_DE_PROCESO" bigint NOT NULL,
    "ID_INSTANCIA_DE_PROCESO_ANTECESOR" bigint NOT NULL,
    "ID_USUARIO" character varying(30) NOT NULL,
    "D_FECHA" timestamp(6) without time zone NOT NULL,
    "A_TIPO_ACCION" character varying(100) NOT NULL,
    "A_COMENTARIO" text NOT NULL,
    "B_VIGENTE" boolean
);


ALTER TABLE sgdp."SGDP_HISTORICO_VINCULACION_EXP" OWNER TO sgdp;

--
-- Name: SGDP_INSTANCIAS_DE_PROCESOS; Type: TABLE; Schema: sgdp; Owner: sgdp
--

CREATE TABLE sgdp."SGDP_INSTANCIAS_DE_PROCESOS" (
    "ID_INSTANCIA_DE_PROCESO" bigint DEFAULT nextval('sgdp."SEQ_ID_INSTANCIA_DE_PROCESO"'::regclass) NOT NULL,
    "ID_PROCESO" bigint NOT NULL,
    "D_FECHA_INICIO" timestamp(6) without time zone NOT NULL,
    "D_FECHA_FIN" timestamp(6) without time zone,
    "A_NOMBRE_EXPEDIENTE" character varying(100),
    "D_FECHA_VENCIMIENTO_USUARIO" timestamp(6) without time zone,
    "ID_ESTADO_DE_PROCESO" bigint NOT NULL,
    "ID_EXPEDIENTE" character varying(100),
    "ID_INSTANCIA_DE_PROCESO_PADRE" bigint,
    "ID_USUARIO_INICIA" character varying(30) NOT NULL,
    "ID_USUARIO_TERMINA" character varying(30),
    "B_TIENE_DOCUMENTOS_EN_CMS" boolean,
    "D_FECHA_VENCIMIENTO" timestamp(6) without time zone,
    "A_EMISOR" character varying(1000),
    "A_ASUNTO" character varying(1000),
    "ID_UNIDAD" bigint,
    "ID_ACCESO" bigint,
    "ID_INSTANCIA_PROCESO_METADATA" bigint,
    "ID_TIPO" bigint,
    "D_FECHA_EXPIRACION" timestamp without time zone
);


ALTER TABLE sgdp."SGDP_INSTANCIAS_DE_PROCESOS" OWNER TO sgdp;

--
-- Name: SGDP_INSTANCIAS_DE_TAREAS; Type: TABLE; Schema: sgdp; Owner: sgdp
--

CREATE TABLE sgdp."SGDP_INSTANCIAS_DE_TAREAS" (
    "ID_INSTANCIA_DE_TAREA" bigint NOT NULL,
    "ID_INSTANCIA_DE_PROCESO" bigint NOT NULL,
    "ID_TAREA" bigint NOT NULL,
    "D_FECHA_ASIGNACION" timestamp(6) without time zone NOT NULL,
    "D_FECHA_INICIO" timestamp(6) without time zone,
    "D_FECHA_FINALIZACION" timestamp(6) without time zone,
    "D_FECHA_ANULACION" timestamp(6) without time zone,
    "A_RAZON_ANULACION" character varying(1000),
    "D_FECHA_VENCIMIENTO" timestamp(6) without time zone,
    "ID_ESTADO_DE_TAREA" bigint,
    "D_FECHA_VENCIMIENTO_USUARIO" timestamp(6) without time zone,
    "ID_USUARIO_QUE_ASIGNA" character varying(30)
);


ALTER TABLE sgdp."SGDP_INSTANCIAS_DE_TAREAS" OWNER TO sgdp;

--
-- Name: SGDP_INSTANCIAS_DE_TAREAS_LIBRES; Type: TABLE; Schema: sgdp; Owner: sgdp
--

CREATE TABLE sgdp."SGDP_INSTANCIAS_DE_TAREAS_LIBRES" (
    "ID_INSTANCIA_DE_TAREA_LIBRE" bigint DEFAULT nextval('sgdp."SEQ_ID_INSTANCIA_DE_TAREA_LIBRE"'::regclass) NOT NULL,
    "ID_USUARIO_QUE_HACE_CONSULTA" character varying(30) NOT NULL,
    "ID_USUARIO_ASIGANDO" character varying(30) NOT NULL,
    "ID_INSTANCIA_DE_TAREA" bigint NOT NULL,
    "D_FECHA_ASIGNACION" timestamp(6) without time zone NOT NULL,
    "D_FECHA_FINALIZACION" timestamp(6) without time zone,
    "ID_ESTADO_DE_TAREA" bigint NOT NULL,
    "D_FECHA_VENCIMIENTO" timestamp(6) without time zone,
    "ID_TIPO_DE_TAREA_LIBRE" bigint NOT NULL,
    "ID_INSTANCIA_DE_TAREA_LIBRE_PADRE" bigint
);


ALTER TABLE sgdp."SGDP_INSTANCIAS_DE_TAREAS_LIBRES" OWNER TO sgdp;

--
-- Name: SGDP_INSTANCIA_PROCESO_METADATA; Type: TABLE; Schema: sgdp; Owner: sgdp
--

CREATE TABLE sgdp."SGDP_INSTANCIA_PROCESO_METADATA" (
    "ID_INSTANCIA_PROCESO_METADATA" bigint DEFAULT nextval('sgdp."SEQ_ID_INSTANCIA_PROCESO_METADATA"'::regclass) NOT NULL,
    "A_TITULO" character varying(200),
    "A_NOMBRE_INTERESADO" character varying(200),
    "A_APELLIDO_PATERNO" character varying(200),
    "A_APELLIDO_MATERNO" character varying(200),
    "A_RUT" character varying(20),
    "A_ETIQUETAS" character varying(1000),
    "A_REGION" character varying(200),
    "A_COMUNA" character varying(200),
    "A_METADATA_CUSTOM" text,
    "D_FECHA_CREACION" timestamp without time zone
);


ALTER TABLE sgdp."SGDP_INSTANCIA_PROCESO_METADATA" OWNER TO sgdp;

--
-- Name: SGDP_LISTA_DE_DISTRIBUCION; Type: TABLE; Schema: sgdp; Owner: sgdp
--

CREATE TABLE sgdp."SGDP_LISTA_DE_DISTRIBUCION" (
    "ID_LISTA_DE_DISTRIBUCION" bigint DEFAULT nextval('sgdp."SEQ_ID_LISTA_DE_DISTRIBUCION"'::regclass) NOT NULL,
    "A_NOMBRE_COMPLETO" character varying(5000) NOT NULL,
    "A_EMAIL" character varying(5000) NOT NULL,
    "A_ORGANIZACION" character varying(10000),
    "A_CARGO" character varying(10000)
);


ALTER TABLE sgdp."SGDP_LISTA_DE_DISTRIBUCION" OWNER TO sgdp;

--
-- Name: SGDP_LOG_CARGA; Type: TABLE; Schema: sgdp; Owner: sgdp
--

CREATE TABLE sgdp."SGDP_LOG_CARGA" (
    "ID_LOG_CARGA" bigint DEFAULT nextval('sgdp."SEQ_ID_LOG_CARGA"'::regclass) NOT NULL,
    "ID_CARGA" bigint NOT NULL,
    "A_DESCRIPCION" character varying(1000),
    "D_FECHA_CREACION" timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE sgdp."SGDP_LOG_CARGA" OWNER TO sgdp;

--
-- Name: SGDP_LOG_ERROR; Type: TABLE; Schema: sgdp; Owner: sgdp
--

CREATE TABLE sgdp."SGDP_LOG_ERROR" (
    "ID_LOG_ERROR" bigint DEFAULT nextval('sgdp."SEQ_ID_LOG_ERROR"'::regclass) NOT NULL,
    "A_NOMBRE_ERROR" character varying(30) NOT NULL,
    "A_MENSAJE_EXCEPCION" text NOT NULL,
    "D_FECHA_ERROR" timestamp(6) without time zone NOT NULL,
    "ID_USUARIO" character varying(30) NOT NULL,
    "A_DATOS_ADICIONALES" text
);


ALTER TABLE sgdp."SGDP_LOG_ERROR" OWNER TO sgdp;

--
-- Name: SGDP_LOG_FUERA_DE_OFICINA; Type: TABLE; Schema: sgdp; Owner: sgdp
--

CREATE TABLE sgdp."SGDP_LOG_FUERA_DE_OFICINA" (
    "ID_LOG_FUERA_DE_OFICINA" bigint NOT NULL,
    "ID_USUARIO" character varying(30) NOT NULL,
    "D_FECHA_ACTUALIZACION" timestamp(6) without time zone NOT NULL,
    "B_FUERA_DE_OFICINA" boolean NOT NULL
);


ALTER TABLE sgdp."SGDP_LOG_FUERA_DE_OFICINA" OWNER TO sgdp;

--
-- Name: SGDP_LOG_TRANSACCIONES; Type: TABLE; Schema: sgdp; Owner: sgdp
--

CREATE TABLE sgdp."SGDP_LOG_TRANSACCIONES" (
    "ID_LOG_TRANSACCION" bigint NOT NULL,
    "A_NOMBRE_TABLA" character varying(30) NOT NULL,
    "A_ACCION" character varying(30) NOT NULL,
    "ID_USUARIO" character varying(30) NOT NULL,
    "D_FECHA_TRANSACCION" timestamp(6) without time zone,
    "A_PARAMETROS" character varying(4000) NOT NULL
);


ALTER TABLE sgdp."SGDP_LOG_TRANSACCIONES" OWNER TO sgdp;

--
-- Name: SGDP_MACRO_PROCESOS; Type: TABLE; Schema: sgdp; Owner: sgdp
--

CREATE TABLE sgdp."SGDP_MACRO_PROCESOS" (
    "ID_MACRO_PROCESO" bigint DEFAULT nextval('sgdp."SEQ_ID_MACRO_PROCESO"'::regclass) NOT NULL,
    "A_NOMBRE_MACRO_PROCESO" character varying(100) NOT NULL,
    "A_DESCRIPCION_MACRO_PROCESO" character varying(100),
    "ID_PERSPECTIVA" bigint NOT NULL
);


ALTER TABLE sgdp."SGDP_MACRO_PROCESOS" OWNER TO sgdp;

--
-- Name: SGDP_PARAMETROS; Type: TABLE; Schema: sgdp; Owner: sgdp
--

CREATE TABLE sgdp."SGDP_PARAMETROS" (
    "ID_PARAMETRO" bigint DEFAULT nextval('sgdp."SEQ_ID_PARAMETRO"'::regclass) NOT NULL,
    "A_NOMBRE_PARAMETRO" character varying(200),
    "A_VALOR_PARAMETRO_CHAR" character varying(10000),
    "N_VALOR_PARAMETRO_NUMERICO" integer
);


ALTER TABLE sgdp."SGDP_PARAMETROS" OWNER TO sgdp;

--
-- Name: SGDP_PARAMETROS_ARCHIVO_NACIONAL; Type: TABLE; Schema: sgdp; Owner: sgdp
--

CREATE TABLE sgdp."SGDP_PARAMETROS_ARCHIVO_NACIONAL" (
    "ID_PARAMETRO_ARCHIVO_NACIONAL" bigint DEFAULT nextval('sgdp."SEQ_ID_PARAMETRO_ARCHIVO_NACIONAL"'::regclass) NOT NULL,
    "A_NOMBRE_PARAMETRO" character varying(200),
    "A_VALOR_PARAMETRO_CHAR" character varying(100),
    "D_FECHA_CREACION" timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    "D_FECHA_ACTUALIZACION" timestamp without time zone
);


ALTER TABLE sgdp."SGDP_PARAMETROS_ARCHIVO_NACIONAL" OWNER TO sgdp;

--
-- Name: SGDP_PARAMETROS_POR_CONTEXTO; Type: TABLE; Schema: sgdp; Owner: sgdp
--

CREATE TABLE sgdp."SGDP_PARAMETROS_POR_CONTEXTO" (
    "ID_PARAMETRO_POR_CONTEXTO" bigint DEFAULT nextval('sgdp."SEQ_ID_PARAMETRO_POR_CONTEXTO"'::regclass) NOT NULL,
    "A_NOMBRE_PARAMETRO" character varying(250),
    "A_VALOR_CONTEXTO" character varying(250),
    "A_VALOR_PARAMETRO_CHAR" text,
    "N_VALOR_PARAMETRO_NUMERICO" integer
);


ALTER TABLE sgdp."SGDP_PARAMETROS_POR_CONTEXTO" OWNER TO sgdp;

--
-- Name: SGDP_PARAMETRO_DE_TAREA; Type: TABLE; Schema: sgdp; Owner: sgdp
--

CREATE TABLE sgdp."SGDP_PARAMETRO_DE_TAREA" (
    "ID_PARAM_TAREA" bigint DEFAULT nextval('sgdp."SEQ_ID_PARAM_TAREA"'::regclass) NOT NULL,
    "A_NOMBRE_PARAM_TAREA" character varying(255) NOT NULL,
    "ID_TIPO_PARAMETRO_DE_TAREA" bigint,
    "A_TITULO" character varying(255)
);


ALTER TABLE sgdp."SGDP_PARAMETRO_DE_TAREA" OWNER TO sgdp;

--
-- Name: SGDP_PARAMETRO_RELACION_TAREA; Type: TABLE; Schema: sgdp; Owner: sgdp
--

CREATE TABLE sgdp."SGDP_PARAMETRO_RELACION_TAREA" (
    "ID_TAREA" bigint NOT NULL,
    "ID_PARAM_TAREA" bigint NOT NULL
);


ALTER TABLE sgdp."SGDP_PARAMETRO_RELACION_TAREA" OWNER TO sgdp;

--
-- Name: SGDP_PERMISOS; Type: TABLE; Schema: sgdp; Owner: sgdp
--

CREATE TABLE sgdp."SGDP_PERMISOS" (
    "ID_PERMISO" bigint DEFAULT nextval('sgdp."SEQ_ID_PERMISO"'::regclass) NOT NULL,
    "A_NOMBRE_PERMISO" character varying(250) NOT NULL,
    "ID_ROL" bigint NOT NULL
);


ALTER TABLE sgdp."SGDP_PERMISOS" OWNER TO sgdp;

--
-- Name: SGDP_PERSPECTIVAS; Type: TABLE; Schema: sgdp; Owner: sgdp
--

CREATE TABLE sgdp."SGDP_PERSPECTIVAS" (
    "ID_PERSPECTIVA" bigint DEFAULT nextval('sgdp."SEQ_ID_PERSPECTIVA"'::regclass) NOT NULL,
    "A_NOMBRE_PERSPECTIVA" character varying(100) NOT NULL,
    "A_DESCRIPCION_PERSPECTIVA" character varying(100)
);


ALTER TABLE sgdp."SGDP_PERSPECTIVAS" OWNER TO sgdp;

--
-- Name: SGDP_PROCESOS; Type: TABLE; Schema: sgdp; Owner: sgdp
--

CREATE TABLE sgdp."SGDP_PROCESOS" (
    "ID_PROCESO" bigint DEFAULT nextval('sgdp."SEQ_ID_PROCESO"'::regclass) NOT NULL,
    "A_NOMBRE_PROCESO" character varying(500) NOT NULL,
    "A_DESCRIPCION_PROCESO" character varying(500),
    "ID_MACRO_PROCESO" bigint NOT NULL,
    "B_VIGENTE" boolean,
    "N_DIAS_HABILES_MAX_DURACION" integer NOT NULL,
    "ID_UNIDAD" bigint,
    "B_CONFIDENCIAL" boolean,
    "X_BPMN" text,
    "A_CODIGO_PROCESO" character varying(20),
    "D_FECHA_CREACION" timestamp(6) without time zone
);


ALTER TABLE sgdp."SGDP_PROCESOS" OWNER TO sgdp;

--
-- Name: SGDP_PROCESO_FORM_CREA_EXP; Type: TABLE; Schema: sgdp; Owner: sgdp
--

CREATE TABLE sgdp."SGDP_PROCESO_FORM_CREA_EXP" (
    "ID_PROCESO_FORM_CREA_EXP" bigint DEFAULT nextval('sgdp."SEQ_ID_PROCESO_FORM_CREA_EXP"'::regclass) NOT NULL,
    "A_CODIGO_PROCESO" character varying(20),
    "ID_USUARIO" character varying(30) NOT NULL,
    "D_FECHA" timestamp(6) without time zone NOT NULL
);


ALTER TABLE sgdp."SGDP_PROCESO_FORM_CREA_EXP" OWNER TO sgdp;

--
-- Name: SGDP_REFERENCIAS_DE_TAREAS; Type: TABLE; Schema: sgdp; Owner: sgdp
--

CREATE TABLE sgdp."SGDP_REFERENCIAS_DE_TAREAS" (
    "ID_REFERENCIA_DE_TAREA" bigint DEFAULT nextval('sgdp."SEQ_ID_REFERENCIA_DE_TAREA"'::regclass) NOT NULL,
    "ID_TAREA" bigint,
    "ID_TAREA_SIGUIENTE" bigint
);


ALTER TABLE sgdp."SGDP_REFERENCIAS_DE_TAREAS" OWNER TO sgdp;

--
-- Name: SGDP_RESPONSABILIDAD; Type: TABLE; Schema: sgdp; Owner: sgdp
--

CREATE TABLE sgdp."SGDP_RESPONSABILIDAD" (
    "ID_RESPONSABILIDAD" bigint DEFAULT nextval('sgdp."SEQ_ID_RESPONSABILIDAD"'::regclass) NOT NULL,
    "A_NOMBRE_RESPONSABILIDAD" character varying(255) NOT NULL
);


ALTER TABLE sgdp."SGDP_RESPONSABILIDAD" OWNER TO sgdp;

--
-- Name: SGDP_RESPONSABILIDAD_TAREA; Type: TABLE; Schema: sgdp; Owner: sgdp
--

CREATE TABLE sgdp."SGDP_RESPONSABILIDAD_TAREA" (
    "ID_RESPONSABILIDAD" bigint NOT NULL,
    "ID_TAREA" bigint NOT NULL
);


ALTER TABLE sgdp."SGDP_RESPONSABILIDAD_TAREA" OWNER TO sgdp;

--
-- Name: SGDP_ROLES; Type: TABLE; Schema: sgdp; Owner: sgdp
--

CREATE TABLE sgdp."SGDP_ROLES" (
    "ID_ROL" bigint DEFAULT nextval('sgdp."SEQ_ID_ROL"'::regclass) NOT NULL,
    "A_NOMBRE_ROL" character varying(30) NOT NULL
);


ALTER TABLE sgdp."SGDP_ROLES" OWNER TO sgdp;

--
-- Name: SGDP_SEGUIMIENTO_INTANCIA_PROCESOS; Type: TABLE; Schema: sgdp; Owner: sgdp
--

CREATE TABLE sgdp."SGDP_SEGUIMIENTO_INTANCIA_PROCESOS" (
    "ID_INSTANCIA_PROCESO" bigint NOT NULL,
    "ID_USUARIO" character varying(64) NOT NULL,
    "A_TIPO_DE_NOTIFICACION" character varying(255)
);


ALTER TABLE sgdp."SGDP_SEGUIMIENTO_INTANCIA_PROCESOS" OWNER TO sgdp;

--
-- Name: SGDP_SOLICITUD_CREACION_EXP; Type: TABLE; Schema: sgdp; Owner: sgdp
--

CREATE TABLE sgdp."SGDP_SOLICITUD_CREACION_EXP" (
    "ID_SOLICITUD_CREACION_EXP" bigint NOT NULL,
    "ID_INSTANCIA_DE_PROCESO" bigint,
    "ID_USUARIO_SOLICITANTE" character varying(30) NOT NULL,
    "ID_USUARIO_CREADOR_EXPEDIENTE" character varying(30),
    "ID_USUARIO_DESTINATARIO" character varying(30),
    "D_FECHA_SOLICITUD" timestamp(6) without time zone NOT NULL,
    "D_FECHA_ATENCION" timestamp(6) without time zone,
    "A_COMENTARIO" text,
    "ID_ESTADO_SOLICITUD_CREACION_EXP" bigint NOT NULL,
    "ID_PROCESO" bigint,
    "A_ASUNTO_MATERIA" character varying(1000) NOT NULL,
    "ID_AUTOR" bigint
);


ALTER TABLE sgdp."SGDP_SOLICITUD_CREACION_EXP" OWNER TO sgdp;

--
-- Name: SGDP_TAREAS; Type: TABLE; Schema: sgdp; Owner: sgdp
--

CREATE TABLE sgdp."SGDP_TAREAS" (
    "ID_TAREA" bigint DEFAULT nextval('sgdp."SEQ_ID_TAREA"'::regclass) NOT NULL,
    "A_NOMBRE_TAREA" character varying(500) NOT NULL,
    "A_DESCRIPCION_TAREA" character varying(500),
    "ID_PROCESO" bigint NOT NULL,
    "N_DIAS_HABILES_MAX_DURACION" integer NOT NULL,
    "N_ORDEN" integer NOT NULL,
    "B_VIGENTE" boolean,
    "B_SOLO_INFORMAR" boolean,
    "ID_ETAPA" bigint,
    "B_OBLIGATORIA" boolean,
    "B_ES_ULTIMA_TAREA" boolean,
    "A_TIPO_DE_BIFURCACION" character varying(250),
    "B_PUEDE_VISAR_DOCUMENTOS" boolean,
    "B_PUEDE_APLICAR_FEA" boolean,
    "A_URL_CONTROL" character varying(255),
    "ID_DIAGRAMA" character varying(1000),
    "B_ASIGNA_NUM_DOC" boolean,
    "B_ESPERAR_RESP" boolean,
    "B_CONFORMA_EXPEDIENTE" boolean,
    "N_DIAS_RESETEO" integer,
    "A_TIPO_RESETEO" character varying(255),
    "A_URL_WS" character varying(250),
    "B_DISTRIBUYE" boolean,
    "B_NUMERACION_AUTO" boolean
);


ALTER TABLE sgdp."SGDP_TAREAS" OWNER TO sgdp;

--
-- Name: SGDP_TAREAS_INICIA_PROCESOS; Type: TABLE; Schema: sgdp; Owner: sgdp
--

CREATE TABLE sgdp."SGDP_TAREAS_INICIA_PROCESOS" (
    "ID_TAREA_INICIA_PROCESO" bigint DEFAULT nextval('sgdp."SEQ_ID_TAREA_INICIA_PROCESO"'::regclass) NOT NULL,
    "ID_TAREA" bigint NOT NULL,
    "ID_PROCESO" bigint NOT NULL
);


ALTER TABLE sgdp."SGDP_TAREAS_INICIA_PROCESOS" OWNER TO sgdp;

--
-- Name: SGDP_TAREAS_ROLES; Type: TABLE; Schema: sgdp; Owner: sgdp
--

CREATE TABLE sgdp."SGDP_TAREAS_ROLES" (
    "ID_TAREA" bigint NOT NULL,
    "ID_ROL" bigint NOT NULL,
    "N_ORDEN" integer
);


ALTER TABLE sgdp."SGDP_TAREAS_ROLES" OWNER TO sgdp;

--
-- Name: SGDP_TEXTO_PARAMETRO_DE_TAREA; Type: TABLE; Schema: sgdp; Owner: sgdp
--

CREATE TABLE sgdp."SGDP_TEXTO_PARAMETRO_DE_TAREA" (
    "ID_TEXTO_PARAMETRO_DE_TAREA" bigint DEFAULT nextval('sgdp."SEQ_ID_TEXTO_PARAMETRO_DE_TAREA"'::regclass) NOT NULL,
    "ID_PARAM_TAREA" bigint,
    "A_TEXTO" character varying(1000) NOT NULL
);


ALTER TABLE sgdp."SGDP_TEXTO_PARAMETRO_DE_TAREA" OWNER TO sgdp;

--
-- Name: SGDP_TIPOS; Type: TABLE; Schema: sgdp; Owner: sgdp
--

CREATE TABLE sgdp."SGDP_TIPOS" (
    "ID_TIPO" bigint DEFAULT nextval('sgdp."SEQ_ID_TIPO"'::regclass) NOT NULL,
    "A_NOMBRE_TIPO" character varying(20),
    "D_FECHA_CREACION" timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE sgdp."SGDP_TIPOS" OWNER TO sgdp;

--
-- Name: SGDP_TIPOS_DE_DOCUMENTOS; Type: TABLE; Schema: sgdp; Owner: sgdp
--

CREATE TABLE sgdp."SGDP_TIPOS_DE_DOCUMENTOS" (
    "ID_TIPO_DE_DOCUMENTO" bigint DEFAULT nextval('sgdp."SEQ_ID_TIPO_DE_DOCUMENTO"'::regclass) NOT NULL,
    "A_NOMBRE_DE_TIPO_DE_DOCUMENTO" text NOT NULL,
    "B_CONFORMA_EXPEDIENTE" boolean,
    "B_APLICA_VISACION" boolean,
    "B_APLICA_FEA" boolean,
    "B_ES_DOCUMENTO_CONDUCTOR" boolean,
    "ID_CATEGORIA_DE_TIPO_DE_DOCUMENTO" bigint,
    "B_NUMERACION_AUTO" boolean,
    "A_COD_TIPO_DOC" character varying(255),
    "A_NOM_COMP_CAT_TIPO_DOC" character varying(255)
);


ALTER TABLE sgdp."SGDP_TIPOS_DE_DOCUMENTOS" OWNER TO sgdp;

--
-- Name: SGDP_TIPOS_DE_TAREAS_LIBRES; Type: TABLE; Schema: sgdp; Owner: sgdp
--

CREATE TABLE sgdp."SGDP_TIPOS_DE_TAREAS_LIBRES" (
    "ID_TIPO_DE_TAREA_LIBRE" bigint NOT NULL,
    "A_NOMBRE_DE_TAREA_LIBRE" character varying(100) NOT NULL
);


ALTER TABLE sgdp."SGDP_TIPOS_DE_TAREAS_LIBRES" OWNER TO sgdp;

--
-- Name: SGDP_TIPO_PARAMETRO_DE_TAREA; Type: TABLE; Schema: sgdp; Owner: sgdp
--

CREATE TABLE sgdp."SGDP_TIPO_PARAMETRO_DE_TAREA" (
    "ID_TIPO_PARAMETRO_DE_TAREA" bigint DEFAULT nextval('sgdp."SEQ_ID_TIPO_PARAMETRO_DE_TAREA"'::regclass) NOT NULL,
    "A_NOMBRE_TIPO_PARAMETRO_DE_TAREA" character varying(1000) NOT NULL,
    "A_TEXTO_HTML" character varying(5000) NOT NULL,
    "B_COMENTA" boolean
);


ALTER TABLE sgdp."SGDP_TIPO_PARAMETRO_DE_TAREA" OWNER TO sgdp;

--
-- Name: SGDP_UNIDADES; Type: TABLE; Schema: sgdp; Owner: sgdp
--

CREATE TABLE sgdp."SGDP_UNIDADES" (
    "ID_UNIDAD" bigint DEFAULT nextval('sgdp."SEQ_ID_UNIDAD"'::regclass) NOT NULL,
    "A_CODIGO_UNIDAD" character varying(30) NOT NULL,
    "A_NOMBRE_COMPLETO_UNIDAD" character varying(100)
);


ALTER TABLE sgdp."SGDP_UNIDADES" OWNER TO sgdp;

--
-- Name: SGDP_USUARIOS_ASIGNADOS_A_TAREAS; Type: TABLE; Schema: sgdp; Owner: sgdp
--

CREATE TABLE sgdp."SGDP_USUARIOS_ASIGNADOS_A_TAREAS" (
    "ID_INSTANCIA_DE_TAREA" bigint NOT NULL,
    "ID_USUARIO" character varying(30) NOT NULL
);


ALTER TABLE sgdp."SGDP_USUARIOS_ASIGNADOS_A_TAREAS" OWNER TO sgdp;

--
-- Name: SGDP_USUARIOS_ROLES; Type: TABLE; Schema: sgdp; Owner: sgdp
--

CREATE TABLE sgdp."SGDP_USUARIOS_ROLES" (
    "ID_USUARIO_ROL" bigint DEFAULT nextval('sgdp."SEQ_ID_USUARIO_ROL"'::regclass) NOT NULL,
    "ID_ROL" bigint NOT NULL,
    "ID_USUARIO" character varying(30) NOT NULL,
    "ID_UNIDAD" bigint,
    "B_ACTIVO" boolean,
    "B_FUERA_DE_OFICINA" boolean,
    "A_NOMBRE_COMPLETO" character varying(200),
    "A_RUT" character varying(20)
);


ALTER TABLE sgdp."SGDP_USUARIOS_ROLES" OWNER TO sgdp;

--
-- Name: SGDP_USUARIO_NOTIFICACION_TAR_ID_USUARIO_NOTIFICACION_TAREA_seq; Type: SEQUENCE; Schema: sgdp; Owner: sgdp
--

CREATE SEQUENCE sgdp."SGDP_USUARIO_NOTIFICACION_TAR_ID_USUARIO_NOTIFICACION_TAREA_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE sgdp."SGDP_USUARIO_NOTIFICACION_TAR_ID_USUARIO_NOTIFICACION_TAREA_seq" OWNER TO sgdp;

--
-- Name: SGDP_USUARIO_NOTIFICACION_TAREA; Type: TABLE; Schema: sgdp; Owner: sgdp
--

CREATE TABLE sgdp."SGDP_USUARIO_NOTIFICACION_TAREA" (
    "ID_USUARIO_NOTIFICACION_TAREA" bigint DEFAULT nextval('sgdp."SGDP_USUARIO_NOTIFICACION_TAR_ID_USUARIO_NOTIFICACION_TAREA_seq"'::regclass) NOT NULL,
    "ID_USUARIO" character varying(30),
    "D_FECHA_CREACION" timestamp(6) without time zone,
    "ID_TAREA" bigint
);


ALTER TABLE sgdp."SGDP_USUARIO_NOTIFICACION_TAREA" OWNER TO sgdp;

--
-- Name: SGDP_USUARIO_NOTIFICACION_TAR_ID_USUARIO_NOTIFI_TAREA_seq2; Type: SEQUENCE; Schema: sgdp; Owner: sgdp
--

CREATE SEQUENCE sgdp."SGDP_USUARIO_NOTIFICACION_TAR_ID_USUARIO_NOTIFI_TAREA_seq2"
    START WITH 77
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE sgdp."SGDP_USUARIO_NOTIFICACION_TAR_ID_USUARIO_NOTIFI_TAREA_seq2" OWNER TO sgdp;

--
-- Name: SGDP_USUARIO_RESPONSABILIDAD; Type: TABLE; Schema: sgdp; Owner: sgdp
--

CREATE TABLE sgdp."SGDP_USUARIO_RESPONSABILIDAD" (
    "ID_USUARIO" character varying(255) NOT NULL,
    "ID_RESPONSABILIDAD" bigint NOT NULL,
    "ID_USUARIO_RESPONSABILIDAD" bigint DEFAULT nextval('sgdp."SEQ_ID_USUARIO_RESPONSABILIDAD"'::regclass) NOT NULL,
    "N_ORDEN" integer,
    "B_SUBROGANDO" boolean
);


ALTER TABLE sgdp."SGDP_USUARIO_RESPONSABILIDAD" OWNER TO sgdp;

--
-- Name: SGDP_VALOR_PARAMETRO_DE_TAREA; Type: TABLE; Schema: sgdp; Owner: sgdp
--

CREATE TABLE sgdp."SGDP_VALOR_PARAMETRO_DE_TAREA" (
    "ID_VALOR_PARAMETRO_DE_TAREA" bigint DEFAULT nextval('sgdp."SEQ_ID_VALOR_PARAMETRO_DE_TAREA"'::regclass) NOT NULL,
    "ID_PARAM_TAREA" bigint NOT NULL,
    "ID_INSTANCIA_DE_TAREA" bigint NOT NULL,
    "A_VALOR" character varying(5000),
    "D_FECHA" timestamp(6) without time zone,
    "A_COMENTARIO" character varying(10000)
);


ALTER TABLE sgdp."SGDP_VALOR_PARAMETRO_DE_TAREA" OWNER TO sgdp;

--
-- Name: SGDP_VINCULACION_EXP; Type: TABLE; Schema: sgdp; Owner: sgdp
--

CREATE TABLE sgdp."SGDP_VINCULACION_EXP" (
    "ID_VINCULACION_EXP" bigint NOT NULL,
    "ID_INSTANCIA_DE_PROCESO" bigint NOT NULL,
    "ID_INSTANCIA_DE_PROCESO_ANTECESOR" bigint NOT NULL,
    "ID_USUARIO" character varying(30) NOT NULL,
    "D_FECHA_VINCULACION" timestamp(6) without time zone NOT NULL,
    "A_COMENTARIO" text NOT NULL
);


ALTER TABLE sgdp."SGDP_VINCULACION_EXP" OWNER TO sgdp;

--
-- Data for Name: SGDP_ACCESOS; Type: TABLE DATA; Schema: sgdp; Owner: sgdp
--

COPY sgdp."SGDP_ACCESOS" ("ID_ACCESO", "A_NOMBRE_ACCESO", "A_VALOR_ACCESO_CHAR", "D_FECHA_CREACION") FROM stdin;
1	PUBLICO	Publico	2021-03-19 15:54:11.352171+00
2	SECRETO	Secreto	2021-03-19 15:54:11.352171+00
3	RESERVADO	Reservado	2021-03-19 15:54:11.352171+00
-1	COMODIN	Comodin	2021-03-19 15:54:11.353098+00
\.


--
-- Data for Name: SGDP_ACCIONES_HIST_INST_DE_TAREAS; Type: TABLE DATA; Schema: sgdp; Owner: sgdp
--

COPY sgdp."SGDP_ACCIONES_HIST_INST_DE_TAREAS" ("ID_ACCION_HISTORICO_INST_DE_TAREA", "A_NOMBRE_ACCION", "A_DESC_ACCION") FROM stdin;
1	CREA	CREÓ
2	DEVUELVE	DEVOLVIÓ
3	ENVIA	ENVIÓ
4	REASIGNA	REASIGNÓ
5	DESPACHA	DESPACHÓ
6	FINALIZA	FINALIZÓ
7	ANULA	ANULÓ
8	REABRE	REABRIÓ
9	CERRAR	CERRÓ
10	ABRE	ABRIÓ
11	SUBE	SUBIÓ ARCHIVOS
\.


--
-- Data for Name: SGDP_ARCHIVOS_INST_DE_TAREA; Type: TABLE DATA; Schema: sgdp; Owner: sgdp
--

COPY sgdp."SGDP_ARCHIVOS_INST_DE_TAREA" ("ID_ARCHIVOS_INST_DE_TAREA", "ID_INSTANCIA_DE_TAREA", "A_NOMBRE_ARCHIVO", "A_MIME_TYPE", "ID_ARCHIVO_CMS", "A_VERSION", "ID_TIPO_DE_DOCUMENTO", "ID_USUARIO", "D_FECHA_SUBIDO", "B_ESTA_VISADO", "B_ESTA_FIRMADO_CON_FEA_WEB_START", "B_ESTA_FIRMADO_CON_FEA_CENTRALIZADA", "D_FECHA_DOCUMENTO", "D_FECHA_RECEPCION", "ID_ARCHIVOS_INST_DE_TAREA_METADATA") FROM stdin;
\.


--
-- Data for Name: SGDP_ARCHIVOS_INST_DE_TAREA_METADATA; Type: TABLE DATA; Schema: sgdp; Owner: sgdp
--

COPY sgdp."SGDP_ARCHIVOS_INST_DE_TAREA_METADATA" ("ID_ARCHIVOS_INST_DE_TAREA_METADATA", "ID_TIPO", "A_TITULO", "A_AUTOR", "A_DESTINATARIOS", "B_DIGITALIZADO", "D_FECHA_DOCUMENTO", "A_NOMBRE_INTERESADO", "A_APELLIDO_PATERNO", "A_APELLIDO_MATERNO", "A_RUT", "A_ETIQUETAS", "A_REGION", "A_COMUNA", "A_METADATA_CUSTOM", "N_FLAG_ENVIO") FROM stdin;
\.


--
-- Data for Name: SGDP_ASIGNACIONES_NUMEROS_DOC; Type: TABLE DATA; Schema: sgdp; Owner: sgdp
--

COPY sgdp."SGDP_ASIGNACIONES_NUMEROS_DOC" ("ID_ASIGNACION_NUMERO_DOC", "N_NUMERO_DOCUMENTO", "ID_TIPO_DE_DOCUMENTO", "A_ESTADO", "D_ANIO", "D_FECHA_CREACION", "D_FECHA_MODIFICACION") FROM stdin;
\.


--
-- Data for Name: SGDP_AUTORES; Type: TABLE DATA; Schema: sgdp; Owner: sgdp
--

COPY sgdp."SGDP_AUTORES" ("ID_AUTOR", "A_NOMBRE_AUTOR") FROM stdin;
1	CONTRALORIA
2	MINISTERIO DE HACIENDA
3	HOMOLOGACION
4	SCJ - UTDP
5	DIVISION JURIDICA
6	Sanciones
\.


--
-- Data for Name: SGDP_CARGAS; Type: TABLE DATA; Schema: sgdp; Owner: sgdp
--

COPY sgdp."SGDP_CARGAS" ("ID_CARGA", "N_CANTIDAD_DOCUMENTOS", "A_NOMBRE_SERIE", "A_NOMBRE_ACUERDO", "A_TIPO_ACUERDO", "A_ID_TRANSFERENCIA", "D_FECHA_CREACION") FROM stdin;
\.


--
-- Data for Name: SGDP_CARGO; Type: TABLE DATA; Schema: sgdp; Owner: sgdp
--

COPY sgdp."SGDP_CARGO" ("ID_CARGO", "A_NOMBRE_CARGO") FROM stdin;
\.


--
-- Data for Name: SGDP_CARGO_RESPONSABILIDAD; Type: TABLE DATA; Schema: sgdp; Owner: sgdp
--

COPY sgdp."SGDP_CARGO_RESPONSABILIDAD" ("ID_CARGO", "ID_RESPONSABILIDAD") FROM stdin;
\.


--
-- Data for Name: SGDP_CARGO_USUARIO_ROL; Type: TABLE DATA; Schema: sgdp; Owner: sgdp
--

COPY sgdp."SGDP_CARGO_USUARIO_ROL" ("ID_CARGO", "ID_USUARIO_ROL") FROM stdin;
\.


--
-- Data for Name: SGDP_CATEGORIA_DE_TIPO_DE_DOCUMENTO; Type: TABLE DATA; Schema: sgdp; Owner: sgdp
--

COPY sgdp."SGDP_CATEGORIA_DE_TIPO_DE_DOCUMENTO" ("ID_CATEGORIA_DE_TIPO_DE_DOCUMENTO", "A_NOMBRE_DE_CATEGORIA_DE_TIPO_DE_DOCUMENTO") FROM stdin;
\.


--
-- Data for Name: SGDP_DETALLES_CARGA; Type: TABLE DATA; Schema: sgdp; Owner: sgdp
--

COPY sgdp."SGDP_DETALLES_CARGA" ("ID_DETALLE_CARGA", "ID_CARGA", "A_NOMBRE_DOCUMENTO", "A_ID_ARCHIVO_CMS", "D_FECHA_CREACION") FROM stdin;
\.


--
-- Data for Name: SGDP_DOCUMENTOS_DE_SALIDA_DE_TAREAS; Type: TABLE DATA; Schema: sgdp; Owner: sgdp
--

COPY sgdp."SGDP_DOCUMENTOS_DE_SALIDA_DE_TAREAS" ("ID_TAREA", "ID_TIPO_DE_DOCUMENTO", "N_ORDEN") FROM stdin;
\.


--
-- Data for Name: SGDP_ESTADOS_DE_PROCESOS; Type: TABLE DATA; Schema: sgdp; Owner: sgdp
--

COPY sgdp."SGDP_ESTADOS_DE_PROCESOS" ("ID_ESTADO_DE_PROCESO", "N_CODIGO_ESTADO_DE_PROCESO", "A_NOMBRE_ESTADO_DE_PROCESO") FROM stdin;
1	1	NUEVO
2	2	ASIGNADO
3	3	FINALIZADO
4	4	ANULADO
\.


--
-- Data for Name: SGDP_ESTADOS_DE_TAREAS; Type: TABLE DATA; Schema: sgdp; Owner: sgdp
--

COPY sgdp."SGDP_ESTADOS_DE_TAREAS" ("ID_ESTADO_DE_TAREA", "N_CODIGO_ESTADO_DE_TAREA", "A_NOMBRE_ESTADO_DE_TAREA") FROM stdin;
1	1	NUEVA
2	2	ASIGNADA
3	3	FINALIZADA
4	4	ANULADA
\.


--
-- Data for Name: SGDP_ESTADO_SOLICITUD_CREACION_EXP; Type: TABLE DATA; Schema: sgdp; Owner: sgdp
--

COPY sgdp."SGDP_ESTADO_SOLICITUD_CREACION_EXP" ("ID_ESTADO_SOLICITUD_CREACION_EXP", "A_NOMBRE_ESTADO_SOLICITUD_CREACION_EXP") FROM stdin;
1	NUEVA
2	SOLICITADA
3	RECHAZADA
4	SOLICITADA_EXT
5	CREADA
\.


--
-- Data for Name: SGDP_ETAPAS; Type: TABLE DATA; Schema: sgdp; Owner: sgdp
--

COPY sgdp."SGDP_ETAPAS" ("ID_ETAPA", "A_NOMBRE_ETAPA") FROM stdin;
1	Ingresar
2	Asignación
3	Análisis en división
4	VB Jefe / Visación Jurídica
5	Firma Superintendente
6	Análisis técnico otra Div / Un
7	Despacho
8	Distribución
\.


--
-- Data for Name: SGDP_FECHAS_FERIADOS; Type: TABLE DATA; Schema: sgdp; Owner: sgdp
--

COPY sgdp."SGDP_FECHAS_FERIADOS" ("A_FECHA_FERIADO", "D_FECHA_FERIADO") FROM stdin;
\.


--
-- Data for Name: SGDP_HISTORICO_ACCIONES_INST_DE_TAREAS; Type: TABLE DATA; Schema: sgdp; Owner: sgdp
--

COPY sgdp."SGDP_HISTORICO_ACCIONES_INST_DE_TAREAS" ("ID_HISTORICO_ACCIONES_INST_DE_TAREAS", "A_NOMBRE_ACCION") FROM stdin;
\.


--
-- Data for Name: SGDP_HISTORICO_ARCHIVOS_INST_DE_TAREAS; Type: TABLE DATA; Schema: sgdp; Owner: sgdp
--

COPY sgdp."SGDP_HISTORICO_ARCHIVOS_INST_DE_TAREAS" ("ID_HISTORICO_DE_INST_DE_TAREA", "A_NOMBRE_ARCHIVO", "A_MIME_TYPE", "ID_ARCHIVO_CMS", "A_VERSION", "ID_HISTORICO_ARCHIVOS_INST_DE_TAREAS", "ID_TIPO_DE_DOCUMENTO", "ID_USUARIO", "D_FECHA_DOCUMENTO", "D_FECHA_RECEPCION", "D_FECHA_SUBIDO") FROM stdin;
\.


--
-- Data for Name: SGDP_HISTORICO_DE_INST_DE_TAREAS; Type: TABLE DATA; Schema: sgdp; Owner: sgdp
--

COPY sgdp."SGDP_HISTORICO_DE_INST_DE_TAREAS" ("ID_HISTORICO_DE_INST_DE_TAREA", "ID_INSTANCIA_DE_TAREA_DE_ORIGEN", "D_FECHA_MOVIMIENTO", "ID_ACCION_HISTORICO_INST_DE_TAREA", "ID_USUARIO_ORIGEN", "ID_INSTANCIA_DE_TAREA_DESTINO", "A_COMENTARIO", "A_MENSAJE_EXCEPCION", "N_DIAS_OCUPADOS", "N_MINUTOS_OCUPADOS", "N_HORAS_OCUPADAS") FROM stdin;
\.


--
-- Data for Name: SGDP_HISTORICO_FECHA_VENC_INS_PROC; Type: TABLE DATA; Schema: sgdp; Owner: sgdp
--

COPY sgdp."SGDP_HISTORICO_FECHA_VENC_INS_PROC" ("ID_HIST_FECHA_VENC_INS_PROC", "ID_INSTANCIA_DE_TAREA", "D_FECHA_VENCIMIENTO", "ID_USUARIO") FROM stdin;
\.


--
-- Data for Name: SGDP_HISTORICO_FIRMAS; Type: TABLE DATA; Schema: sgdp; Owner: sgdp
--

COPY sgdp."SGDP_HISTORICO_FIRMAS" ("ID_HISTORICO_FIRMA", "ID_INSTANCIA_DE_TAREA", "ID_ARCHIVO_CMS", "ID_USUARIO", "D_FECHA_FIRMA", "A_TIPO_FIRMA", "ID_TIPO_DE_DOCUMENTO") FROM stdin;
\.


--
-- Data for Name: SGDP_HISTORICO_SEGUIMIENTO_INTANCIA_PROCESOS; Type: TABLE DATA; Schema: sgdp; Owner: sgdp
--

COPY sgdp."SGDP_HISTORICO_SEGUIMIENTO_INTANCIA_PROCESOS" ("ID_HISTORICO_INSTANCIA_PROCESO", "ID_INSTANCIA_PROCESO", "ID_USUARIO", "ID_USUARIO_ACCION", "A_ACCION", "D_FECHA_ACCION", "A_TIPO_DE_NOTIFICACION") FROM stdin;
\.


--
-- Data for Name: SGDP_HISTORICO_SOLICITUD_CREACION_EXP; Type: TABLE DATA; Schema: sgdp; Owner: sgdp
--

COPY sgdp."SGDP_HISTORICO_SOLICITUD_CREACION_EXP" ("ID_HISTORICO_SOLICITUD_CREACION_EXP", "ID_SOLICITUD_CREACION_EXP", "ID_INSTANCIA_DE_PROCESO", "ID_USUARIO_SOLICITANTE", "ID_USUARIO_CREADOR_EXPEDIENTE", "ID_USUARIO_DESTINATARIO", "D_FECHA_SOLICITUD", "D_FECHA_ATENCION", "A_COMENTARIO", "ID_ESTADO_SOLICITUD_CREACION_EXP", "ID_PROCESO", "A_ASUNTO_MATERIA", "ID_AUTOR", "ID_USUARIO", "D_FECHA", "A_TIPO_ACCION") FROM stdin;
\.


--
-- Data for Name: SGDP_HISTORICO_USUARIOS_ASIGNADOS_A_TAREAS; Type: TABLE DATA; Schema: sgdp; Owner: sgdp
--

COPY sgdp."SGDP_HISTORICO_USUARIOS_ASIGNADOS_A_TAREAS" ("ID_HISTORICO_DE_INST_DE_TAREA", "ID_USUARIO") FROM stdin;
\.


--
-- Data for Name: SGDP_HISTORICO_VALOR_PARAMETRO_DE_TAREA; Type: TABLE DATA; Schema: sgdp; Owner: sgdp
--

COPY sgdp."SGDP_HISTORICO_VALOR_PARAMETRO_DE_TAREA" ("ID_HISTORICO_VALOR_PARAMETRO_DE_TAREA", "ID_PARAM_TAREA", "A_VALOR", "A_COMENTARIO", "ID_HISTORICO_DE_INST_DE_TAREA") FROM stdin;
\.


--
-- Data for Name: SGDP_HISTORICO_VINCULACION_EXP; Type: TABLE DATA; Schema: sgdp; Owner: sgdp
--

COPY sgdp."SGDP_HISTORICO_VINCULACION_EXP" ("ID_HISTORICO_VINCULACION_EXP", "ID_INSTANCIA_DE_PROCESO", "ID_INSTANCIA_DE_PROCESO_ANTECESOR", "ID_USUARIO", "D_FECHA", "A_TIPO_ACCION", "A_COMENTARIO", "B_VIGENTE") FROM stdin;
\.


--
-- Data for Name: SGDP_INSTANCIAS_DE_PROCESOS; Type: TABLE DATA; Schema: sgdp; Owner: sgdp
--

COPY sgdp."SGDP_INSTANCIAS_DE_PROCESOS" ("ID_INSTANCIA_DE_PROCESO", "ID_PROCESO", "D_FECHA_INICIO", "D_FECHA_FIN", "A_NOMBRE_EXPEDIENTE", "D_FECHA_VENCIMIENTO_USUARIO", "ID_ESTADO_DE_PROCESO", "ID_EXPEDIENTE", "ID_INSTANCIA_DE_PROCESO_PADRE", "ID_USUARIO_INICIA", "ID_USUARIO_TERMINA", "B_TIENE_DOCUMENTOS_EN_CMS", "D_FECHA_VENCIMIENTO", "A_EMISOR", "A_ASUNTO", "ID_UNIDAD", "ID_ACCESO", "ID_INSTANCIA_PROCESO_METADATA", "ID_TIPO", "D_FECHA_EXPIRACION") FROM stdin;
\.


--
-- Data for Name: SGDP_INSTANCIAS_DE_TAREAS; Type: TABLE DATA; Schema: sgdp; Owner: sgdp
--

COPY sgdp."SGDP_INSTANCIAS_DE_TAREAS" ("ID_INSTANCIA_DE_TAREA", "ID_INSTANCIA_DE_PROCESO", "ID_TAREA", "D_FECHA_ASIGNACION", "D_FECHA_INICIO", "D_FECHA_FINALIZACION", "D_FECHA_ANULACION", "A_RAZON_ANULACION", "D_FECHA_VENCIMIENTO", "ID_ESTADO_DE_TAREA", "D_FECHA_VENCIMIENTO_USUARIO", "ID_USUARIO_QUE_ASIGNA") FROM stdin;
\.


--
-- Data for Name: SGDP_INSTANCIAS_DE_TAREAS_LIBRES; Type: TABLE DATA; Schema: sgdp; Owner: sgdp
--

COPY sgdp."SGDP_INSTANCIAS_DE_TAREAS_LIBRES" ("ID_INSTANCIA_DE_TAREA_LIBRE", "ID_USUARIO_QUE_HACE_CONSULTA", "ID_USUARIO_ASIGANDO", "ID_INSTANCIA_DE_TAREA", "D_FECHA_ASIGNACION", "D_FECHA_FINALIZACION", "ID_ESTADO_DE_TAREA", "D_FECHA_VENCIMIENTO", "ID_TIPO_DE_TAREA_LIBRE", "ID_INSTANCIA_DE_TAREA_LIBRE_PADRE") FROM stdin;
\.


--
-- Data for Name: SGDP_INSTANCIA_PROCESO_METADATA; Type: TABLE DATA; Schema: sgdp; Owner: sgdp
--

COPY sgdp."SGDP_INSTANCIA_PROCESO_METADATA" ("ID_INSTANCIA_PROCESO_METADATA", "A_TITULO", "A_NOMBRE_INTERESADO", "A_APELLIDO_PATERNO", "A_APELLIDO_MATERNO", "A_RUT", "A_ETIQUETAS", "A_REGION", "A_COMUNA", "A_METADATA_CUSTOM", "D_FECHA_CREACION") FROM stdin;
\.


--
-- Data for Name: SGDP_LISTA_DE_DISTRIBUCION; Type: TABLE DATA; Schema: sgdp; Owner: sgdp
--

COPY sgdp."SGDP_LISTA_DE_DISTRIBUCION" ("ID_LISTA_DE_DISTRIBUCION", "A_NOMBRE_COMPLETO", "A_EMAIL", "A_ORGANIZACION", "A_CARGO") FROM stdin;
\.


--
-- Data for Name: SGDP_LOG_CARGA; Type: TABLE DATA; Schema: sgdp; Owner: sgdp
--

COPY sgdp."SGDP_LOG_CARGA" ("ID_LOG_CARGA", "ID_CARGA", "A_DESCRIPCION", "D_FECHA_CREACION") FROM stdin;
\.


--
-- Data for Name: SGDP_LOG_ERROR; Type: TABLE DATA; Schema: sgdp; Owner: sgdp
--

COPY sgdp."SGDP_LOG_ERROR" ("ID_LOG_ERROR", "A_NOMBRE_ERROR", "A_MENSAJE_EXCEPCION", "D_FECHA_ERROR", "ID_USUARIO", "A_DATOS_ADICIONALES") FROM stdin;
\.


--
-- Data for Name: SGDP_LOG_FUERA_DE_OFICINA; Type: TABLE DATA; Schema: sgdp; Owner: sgdp
--

COPY sgdp."SGDP_LOG_FUERA_DE_OFICINA" ("ID_LOG_FUERA_DE_OFICINA", "ID_USUARIO", "D_FECHA_ACTUALIZACION", "B_FUERA_DE_OFICINA") FROM stdin;
\.


--
-- Data for Name: SGDP_LOG_TRANSACCIONES; Type: TABLE DATA; Schema: sgdp; Owner: sgdp
--

COPY sgdp."SGDP_LOG_TRANSACCIONES" ("ID_LOG_TRANSACCION", "A_NOMBRE_TABLA", "A_ACCION", "ID_USUARIO", "D_FECHA_TRANSACCION", "A_PARAMETROS") FROM stdin;
\.


--
-- Data for Name: SGDP_MACRO_PROCESOS; Type: TABLE DATA; Schema: sgdp; Owner: sgdp
--

COPY sgdp."SGDP_MACRO_PROCESOS" ("ID_MACRO_PROCESO", "A_NOMBRE_MACRO_PROCESO", "A_DESCRIPCION_MACRO_PROCESO", "ID_PERSPECTIVA") FROM stdin;
20	Generación de normas y estándares	\N	2
19	Fiscalizar casinos en operación	\N	2
18	Autorizar laboratorios e implementos de juego	\N	2
17	Interacción con otras Instituciones	\N	2
16	Autorizar funcionamiento de los casinos de juego	\N	2
15	Homologación	\N	1
14	Gestionar el término del permiso de operación	\N	2
13	Planificación estratégica	\N	1
12	Planificación presupuestaria y formulación del plan de compras	\N	1
11	Control de gestión	\N	1
\.


--
-- Data for Name: SGDP_PARAMETROS; Type: TABLE DATA; Schema: sgdp; Owner: sgdp
--

COPY sgdp."SGDP_PARAMETROS" ("ID_PARAMETRO", "A_NOMBRE_PARAMETRO", "A_VALOR_PARAMETRO_CHAR", "N_VALOR_PARAMETRO_NUMERICO") FROM stdin;
1	CMS_REST_URL_LOGIN	http://54.207.252.22:8080/alfresco/service/api/login.json?u={username}&pw={password}	0
2	CMS_REST_URL_CREAR_EXPEDIENTE	http://54.207.252.22:8080/alfresco/s/scj/crearExpediente?alf_ticket={alf_ticket}&creador={creador}&materia={materia}&autor={autor}&perspectiva={perspectiva}&proceso={proceso}&subproceso={subproceso}&nombreExp={nombExp}&esConfidencial={esConfidencial}	0
3	CMS_REST_URL_LOGOUT	http://54.207.252.22:8080/alfresco/service/api/login/ticket/{ticket_logout}?alf_ticket={alf_ticket}	0
4	CMS_REST_URL_VALIDA_SESSION	http://54.207.252.22:8080/alfresco/service/api/login/ticket/{ticket_valida}?alf_ticket={alf_ticket}	0
5	CMS_REST_URL_SUBIR_ARCHIVO	http://54.207.252.22:8080/alfresco/s/scj/subirArchivo	0
6	CMS_PREFIJO_WP_ST	workspace://SpacesStore/	0
7	CMS_REST_URL_OBTENER_ARCHIVOS_EXPEDIENTE	http://54.207.252.22:8080/alfresco/s/scj/obtenerArchivosExpediente?alf_ticket={alf_ticket}&idExpediente={idExpediente}	0
8	CMS_REST_URL_OBTENER_DETALLE_DE_ARCHIVO	http://54.207.252.22:8080/alfresco/s/scj/obtenerDetalleArchivo?alf_ticket={alf_ticket}&idArchivo={id_archivo}	0
9	CMS_REST_URL_OBTENER_TODOS_LOS_TAGS	http://54.207.252.22:8080/alfresco/service/api/tags/workspace/SpacesStore?alf_ticket={alf_ticket}	0
10	CMS_REST_URL_AGREGAR_REMOVER_TAG_DE_OBJETO	http://54.207.252.22:8080/alfresco/service/collaboration/tagActions?alf_ticket={alf_ticket}&a={accion}&n={id_objeto}&t={tag}	0
11	MIME_TYPES_EDITABLES	application/vnd.openxmlformats-officedocument.wordprocessingml.document	1
12	MIME_TYPES_EDITABLES	application/vnd.openxmlformats-officedocument.spreadsheetml.sheet	2
13	MIME_TYPES_EDITABLES	application/msword	1
14	CMS_REST_URL_AGREGAR_COMENTARIO_A_NODO	http://54.207.252.22:8080/alfresco/s/api/node/workspace/SpacesStore/{id}/comments?alf_ticket={alf_ticket}	0
15	TIPOS_DE_DOCUMENTOS_VISABLES	BGI	3
16	CMS_REST_URL_FIRMA_SIMPLE	http://54.207.252.22:8080/alfresco/s/scj/firmasimple?id={idDocumento}&iniciales={iniciales}&alf_ticket={alf_ticket}	0
17	MIME_TYPES_VISABLES	application/pdf	0
18	TIPOS_DE_DOCUMENTOS_APLICA_FEA	BGI	3
19	MIME_TYPES_APLICA_FEA	application/pdf	0
20	TIPOS_DE_DOCUMENTOS_APLICA_FIRMA_APPLET	BGI	3
21	MIME_TYPES_APLICA_FIRMA_APPLET	application/pdf	0
22	REST_URL_FEA	https://apis.digital.gob.cl/firma/v1/files/tickets	0
23	CONNECTION_TIME_OUT_DESCARGA_ARCHIVO_DESDE_URL	5000	5000
24	READ_TIME_OUT_DESCARGA_ARCHIVO_DESDE_URL	5000	5000
25	API_TOKEN_KEY_FEA	sandbox	0
26	PASSWORD_TOKEN_FEA	abcd	0
27	ENTIDAD_TOKEN_FEA	Subsecretaría General de La Presidencia	0
28	CMS_REST_URL_GET_CONTENT	http://54.207.252.22:8080/alfresco/service/api/node/content/workspace/SpacesStore/{id_archivo}/?alf_ticket={alf_ticket}	0
29	ALGORITMO_CHECKSUM_FEA_POST	SHA-256	0
30	PORCENTAJE_ADVERTENCIA_TAREA	20	20
31	REST_URL_FEA_GET_DOCUMENTOS	https://apis.digital.gob.cl/firma/v1/files/tickets/	0
32	STATUS_OK_FILE_FEA	OK	0
33	ALGORITMO_CHECKSUM_FEA_GET	SHA-256	0
34	CMS_REST_URL_GET_ID_DOC_IMAGEN_QR	http://54.207.252.22:8080/alfresco/s/scj/recuperarCodigoQR?nombre={idUsuario}&alf_ticket={alf_ticket}	0
35	URL_IFRAME_MANTENEDORES	http://sgdp_test/parte1/	0
36	CMS_REST_URL_BUSCAR	http://54.207.252.22:8080/alfresco/s/scj/buscar?tipoObjeto={tipoObjeto}&palabraClave={palabraClave}&nombreTipoDocumento={nombreTipoDocumento}&nombreSubprocesoVigente={nombreSubprocesoVigente}&alf_ticket={alf_ticket}	0
37	CMS_SGDP_RELACION_TIPOS_DE_OBJETO_AMBOS_EN_BUSQUEDA	NONE	1
38	ENCODE_CHARACTER_TRANSFORMATION_FEA	UTF-8	0
39	TIPOS_DE_DOCUMENTOS_VISABLES	Oficio de la CGR	4
40	TIPOS_DE_DOCUMENTOS_APLICA_FEA	Oficio de la CGR	4
41	CMS_REST_URL_ACTUALIZA_METADATA_DE_DOCUMENTO	http://54.207.252.22:8080/alfresco/s/scj/actualizarMetadataDocumentos	2
42	TIPOS_DE_DOCUMENTOS_APLICA_FIRMA_APPLET	Oficio de la CGR	5
43	URL_CODE_BASE_JNLP_FEA	"http://172.16.10.77:8080/sgdp"	0
44	MIME_TYPES_CONVERTIBLES_A_PDF	application/msword	0
45	MIME_TYPES_CONVERTIBLES_A_PDF	application/vnd.openxmlformats-officedocument.spreadsheetml.sheet	0
46	MIME_TYPES_CONVERTIBLES_A_PDF	application/vnd.openxmlformats-officedocument.wordprocessingml.document	0
47	CMS_REST_URL_CONVERTIR_ARCHIVO	http://54.207.252.22:8080/alfresco/s/scj/convertirArchivo?idArchivo={id_archivo}&alf_ticket={alf_ticket}	0
48	CMS_IP	http://54.207.252.22:8080	0
49	SGDP_IP	http://172.16.10.77:8080	0
50	EMAIL_REST_URL_ENVIAR	http://172.16.10.77:8080/mailService/enviarMail	0
51	BODY_MENSAJE	<!DOCTYPE html> <html lang='en'>    <head>       <title></title>       <meta charset='utf-8'>    </head>    <body>       <div>          Estimado usuario,<br><br>&emsp;&emsp;El usuario $remitente le ha asignado la siguiente tarea en el sistema de gesti&oacute;n documental y de procesos:          <ul>             <li>SubProceso: $nombreSubProceso</li>             <li>Tarea: $nombreDeTarea</li>             <li>Comentario: $comentario</li>             <li>Expediente: $expediente</li>             <li>Documentos enviados: $documentos</li>             <li>Plazo: <strong>$plazo</strong></li>          </ul>          <br>Para revisarla, por favor dir&iacute;jase al siguiente link:<br><br><a href='$urlSGDP'>Sistema de gesti&oacute;n documental y de procesos</a>       </div>    </body> </html>	0
52	SGDP_URL	http://172.16.10.77:8080/sgdp/	0
54	MIME_TYPES_APLICA_FEA	application/octet-stream	0
55	MIME_TYPES_APLICA_FIRMA_APPLET	application/octet-stream	0
56	CMS_REST_URL_ACT_META_DATA_EXP	http://54.207.252.22:8080/alfresco/s/scj/actualizarMetadataExpediente	0
58	URL_FUNC_PHP	192.168.1.92	0
59	NET_REST_URL_CONVERTIR_ARCHIVO	http://172.16.10.129/Convert	0
60	CMS_REST_URL_GET_ID_DOC_POR_USER_NOM_CARP	http://54.207.252.22:8080/alfresco/s/scj/getIdArchivoPorIdUsrNomCarpeta?idUsuario={idUsuario}&nombreCarpeta={nombreCarpeta}&alf_ticket={alf_ticket}	0
61	NOMBRE_CARPETA_IMAGENES_FEA	Stamper	0
62	CORREO_NOTIFICACION_DOCUMENTOS_CUALQUIER_ETAPA	\n<!DOCTYPE html>\n<html lang='en'>\n<head>\n<title></title>\n<meta charset='utf-8'>\n</head>\n<body>\n\t<div>\n\t\tEstimado usuario,<br>\n\t\t<br>&emsp;&emsp; Se han añadido nuevos antecedentes al proceso $proceso, expediente $Expediente  :\n\t\t<ul>\n\t\t\t$documentos\n\t\t</ul>\n\t\t<br>Para revisarla, por favor dir&iacute;jase al siguiente link:<br>\n\t\t<br>\n\t\t<a href='$urlSGDP'>Sistema de gesti&oacute;n documental y de\n\t\t\tprocesos</a>\n\t</div>\n</body>\n</html>	0
63	ID_PARAM_MAX_DIF_TOLERANCIA_NOMBRE_TIPO_DOC	4	4
64	CMS_REST_URL_BUSCAR_FILTRO_TABLA	http://54.207.252.22:8080/alfresco/s/scj/buscarFiltroTabla?nombreFiltro={nombreFiltro}&tipoFiltro={tipoFiltro}&alf_ticket={alf_ticket}	0
65	CMS_REST_URL_CARGA_FACET	http://54.207.252.22:8080/alfresco/s/scj/cargaFacet?alf_ticket=	0
66	CMS_REST_BUSCA_REGISTROS_PAGINADOS	http://54.207.252.22:8080/alfresco/s/buscarRegistrosPaginados	0
67	BODY_MENSAJE_NOTIFICACION	<!DOCTYPE html> <html lang='en'>    <head>       <title></title>       <meta charset='utf-8'>    </head>    <body>       <div>          Estimado usuario,<br><br>&emsp;&emsp;Se le ha notificado la ejecuci&oacute;n de la siguiente tarea:                                     <ul>             <li>Tarea: $nombreDeTarea</li>             <li>SubProceso: $nombreSubProceso</li>             <li>Expediente: $expediente</li>          </ul>          <br>Para revisarla, por favor dir&iacute;jase al siguiente link:<br> \t\t<br> \t\t<a href='$urlSGDP'>Sistema de gesti&oacute;n documental y de \t\t\tprocesos</a>                         </div>    </body> </html>	0
68	MAIL_SMTP_HOST	172.16.40.11	0
69	TIPO_CONTENIDO_CORREO	text/html; charset=iso-8859-1	0
70	FROM_CORREO	sgdp@scj.gob.cl	0
71	ASUNTO_NOTIFICACION	[SGDP-DESARROLLO] Notificación de ejecución de tarea "$nombreDeTarea" del subproceso "$nombreSubProceso" ($expediente)	0
72	SGDP_CORREO	@scj.gob.cl	0
73	USUSARIOS_EXCLUIDOS	isaynsgdp, ibesgdp, dfsgdp, prtgadmin, user2, user3	0
74	REASON_FEA	Superintendencia de Casinos de Juego	0
75	LOCATION_FEA	Santiago - Chile	0
76	ASUNTO_DISTRIBUCION	[SGDP-QA] Despachos SCJ	0
77	BODY_MENSAJE_DISTRIBUCION	<!DOCTYPE html> <html lang="en"> <head> <title></title> <meta charset="utf-8" /> </head> <body> <div>Estimados (as), se adjuntan documentos del subproceso Tecnova</div> <br /> <br /> <span style="font-size:10.5pt;font-family:&quot;Verdana&quot;,sans-serif; color:#222222">Nota: <br> Se le recuerda que, de acuerdo con lo informado en el Oficio Circular N° 13, desde el viernes 20 de marzo pasado, se encuentra disponible en la Oficina Virtual de nuestro sitio web institucional un Formulario de Contacto (<a href="https://www.superintendenciadecasinos.cl/form_contacto/index.php">https://www.superintendenciadecasinos.cl/form_contacto/index.php</a>) para el envío de documentación, distinta a la que se remite a través de los Sistema de Autorizaciones y Notificaciones (SAYN), Sistema de Autoexclusión Voluntaria de Jugadores y formulario de consultas web; y las solicitudes de homologación que se deben realizar mediante el Sistema de Solicitudes de Homologación de Implementos (SSHI). Excepcionalmente y solo en el caso que el citado formulario no se encontrara disponible por fallas técnicas, se debe enviar un correo con la documentación a la casilla <a href="mailto:opartes@scj.gob.cl">opartes@scj.gob.cl</a>. <o:p></o:p></span> <br /> <br /> <b ><span lang="EN" style="color: #1f497d; mso-ansi-language: EN; mso-fareast-language: ES;" >Saludos cordiales,<u1:p></u1:p></span ></b> <br /> <b ><span lang="EN" style="color: #1f497d; mso-ansi-language: EN; mso-fareast-language: ES;" >Superintendencia de Casinos de Juego</span ></b > <br /> <span style="mso-bookmark: _MailAutoSig;" ><span lang="ES" style=" font-size: 10pt; mso-fareast-font-family: 'Times New Roman'; mso-fareast-theme-font: minor-fareast; color: #1f4e79; mso-ansi-language: ES; mso-fareast-language: ES; mso-no-proof: yes; " >Morand&eacute; 360, piso 11, Santiago, Chile </span></span ><span style="mso-bookmark: _MailAutoSig;" ><span style=" mso-fareast-font-family: 'Times New Roman'; mso-fareast-theme-font: minor-fareast; color: #1f497d; mso-fareast-language: ES-CL; mso-no-proof: yes; " >| </span></span ><span style="mso-bookmark: _MailAutoSig;" ><span lang="ES" style=" font-size: 10pt; mso-fareast-font-family: 'Times New Roman'; mso-fareast-theme-font: minor-fareast; color: #1f4e79; mso-ansi-language: ES; mso-fareast-language: ES; mso-no-proof: yes; " >Tel.: (56 2) 2589 3022 </span></span ><span style="mso-bookmark: _MailAutoSig;" ><span style=" mso-fareast-font-family: 'Times New Roman'; mso-fareast-theme-font: minor-fareast; color: #1f497d; mso-fareast-language: ES-CL; mso-no-proof: yes; " >|</span ></span ><span style="mso-bookmark: _MailAutoSig;" ><span style=" font-size: 10pt; mso-fareast-font-family: 'Times New Roman'; mso-fareast-theme-font: minor-fareast; color: #1f4e79; mso-fareast-language: ES; mso-no-proof: yes; " > </span></span ><span style="mso-bookmark: _MailAutoSig;"></span ><a href="http://www.scj.gob.cl/" ><span style="mso-bookmark: _MailAutoSig;" ><span lang="ES" style=" mso-fareast-font-family: 'Times New Roman'; mso-fareast-theme-font: minor-fareast; color: blue; mso-ansi-language: ES; mso-fareast-language: ES; mso-no-proof: yes; " >www.scj.gob.cl</span ></span ><span style="mso-bookmark: _MailAutoSig;"></span></a ><span style="mso-bookmark: _MailAutoSig;" ><span lang="ES" style=" mso-fareast-font-family: 'Times New Roman'; mso-fareast-theme-font: minor-fareast; color: #1f497d; mso-ansi-language: ES; mso-fareast-language: ES; mso-no-proof: yes; " > <o:p></o:p></span ></span> <br /> <span style="mso-bookmark: _MailAutoSig;" ><span style=" mso-fareast-font-family: 'Times New Roman'; mso-fareast-theme-font: minor-fareast; color: #1f497d; mso-fareast-language: ES-CL; mso-no-proof: yes; " ><!--[if gte vml 1 ]><v:shapetype id="_x0000_t75" coordsize="21600,21600" o:spt="75" o:preferrelative="t" path="m@4@5l@4@11@9@11@9@5xe" filled="f" stroked="f" > <v:stroke joinstyle="miter" /> <v:formulas> <v:f eqn="if lineDrawn pixelLineWidth 0" /> <v:f eqn="sum @0 1 0" /> <v:f eqn="sum 0 0 @1" /> <v:f eqn="prod @2 1 2" /> <v:f eqn="prod @3 21600 pixelWidth" /> <v:f eqn="prod @3 21600 pixelHeight" /> <v:f eqn="sum @0 0 1" /> <v:f eqn="prod @6 1 2" /> <v:f eqn="prod @7 21600 pixelWidth" /> <v:f eqn="sum @8 21600 0" /> <v:f eqn="prod @7 21600 pixelHeight" /> <v:f eqn="sum @10 21600 0" /> </v:formulas> <v:path o:extrusionok="f" gradientshapeok="t" o:connecttype="rect" /> <o:lock v:ext="edit" aspectratio="t" /> </v:shapetype ><v:shape id="Imagen_x0020_1" o:spid="_x0000_i1025" type="#_x0000_t75" alt="Logo SCJ" style=" width: 192pt; height: 51.75pt; visibility: visible; mso-wrap-style: square; " > <v:imagedata src="Sin%20t?tulo_archivos/image001.jpg" o:title="Logo SCJ" /> </v:shape><! [endif]--><![if !vml]> <img src="Tecnova2, Tecnova3" alt="Logo SCJ" v:shapes="Imagen_x0020_1" /> <![endif]></span ></span ><span style="mso-bookmark: _MailAutoSig;" ><span style=" mso-fareast-font-family: 'Times New Roman'; mso-fareast-theme-font: minor-fareast; mso-fareast-language: ES-CL; mso-no-proof: yes; " ><o:p></o:p></span ></span> </body> </html>	0
78	CONTENT_TYPE_ARCHIVO_RESPALDO_CORREO_DISTRIBUCION	message/rfc822	0
79	PRIMERA_PART_NOMBRE_ARCHIVO_RESPALDO_CORREO_DISTRIBUCION	Respaldo Correo Distribución 	0
80	FROM_CORREO_DISTRIBUCION	superintendenciadecasinos-desa@scj.gob.cl	0
81	CODIGO_SRC_IMAGE_CORREO_DISTRIBUCION	data:image/jpg;base64	0
82	ID_SRC_IMAGE_CORREO_DISTRIBUCION	a4515a68-61fd-41fc-a086-d849d2e739ab	0
83	URL_LISTA_INDICADORES	http://172.16.10.77:8080/indicadoresIGestion/indicadorServicios/listaIndicadores	0
84	URL_BUSCA_SUBPROCESO_ASOCIADO_ID_INDICADOR	http://172.16.10.77:8080/indicadoresIGestion/indicadorServicios/buscarSubprocesoAsociadoPorIdIndicador	0
85	URL_REPORTE_SGDP	http://localhost/reporteSGDP	0
86	URL_REGISTRA_DOC_WS	http://172.16.10.215:8080/numeracion-documentos-ws/RegistroDocumentoWS?wsdl	0
87	CMS_ID_LOGO_SCJ_PARA_FIRMA	be7e5237-10b6-46aa-a853-a13e4718f367	0
88	URL_INDICADORES_IGESTION	http://172.16.10.77:8080/indicadoresIGestion/	0
89	URL_NUM_DOC_TIPO_WS	http://172.16.10.215:8080/num-doc-tipo-ws-rest/rest/numDocTipoRest/getTipoDocumentoPorCodTipoDoc/{codTipoDoc}	0
90	COLOCA_IMAGEN_DE_FIRMA	NO	0
91	URL_VERIFICACION_DOC_FEA	Verifique validez en http://www.scj.cl/	0
92	BODY_MENSAJE_NUMERO_DOC	<!DOCTYPE html> <html lang='' en''> <head> <title></title> <meta charset='' utf-8''> </head> <body> <div> Estimado usuario,<br><br>&emsp;&emsp;Se le notifica la test autom&aacute;tica: <ul> <li>SubProceso: $nombreSubProceso</li> <li>Expediente: $expediente</li> <li>Asunto: $asunto</li> <li>Tipo de documento: $tipoDeDocumento</li> <li>N&uacute;mero de documento: $numeroDeDocumento</li> <li>Fecha de documento: $fechaDeDocumento</li> </div> </body> </html>	0
93	NUMERO_DOC_ASUNTO_NOTIFICACION	[SGDP-DESARROLLO] Notificación de sistema de numeración	0
94	USUARIOS_SISTEMAS	isaynsgdp, ibesgdp, dfsgdp, prtgadmin, user2, user3	0
95	ASUNTO_SOL_CREA_EXP	[SGDP-DESARROLLO - SOLICITUD CREACIÓN DE EXPEDIENTE] Notificación de $rechazosolicitud de creación de expediente con id $idSolicitudCreacionExp	0
96	BODY_MENSAJE_SOL_CREA_EXP	<!DOCTYPE html> <html lang=''en''> <head> <title></title> <meta charset=''utf-8''> </head> <body> <div> Estimado usuario,<br><br>&emsp;&emsp;Se le notifica $rechazola solicitud de creaci&oacute;n de expediente: <ul> <li>SubProceso: $nombreSubProceso</li> <li>Asunto: $asunto</li> <li>Destinatario: $destinatario</li> <li>Autor: $autor</li> <li>Comentario: $comentario</li></ul> <br>Para revisarla, por favor dir&iacute;jase al siguiente link:<br> <br> <a href=''$urlSGDP''>Sistema de gesti&oacute;n documental y de procesos</a> </div> </body> </html>	0
97	ASUNTO_CREA_EXP	[SGDP-DESARROLLO - SOLICITUD CREACIÓN DE EXPEDIENTE] Notificación de creación de expediente para solicitud con id $idSolicitudCreacionExp	0
98	BODY_MENSAJE_CREA_EXP	<!DOCTYPE html> <html lang='en'> <head> <title></title> <meta charset='utf-8'> </head> <body> <div> Estimado usuario,<br><br>&emsp;&emsp;Se le notifica la creaci&oacute;n de expediente: <ul> <li>SubProceso: $nombreSubProceso</li> <li>Asunto: $asunto</li> <li>Destinatario: $destinatario</li> <li>Autor: $autor</li> <li>Expediente: $expediente</li> </ul> <br>Para revisarla, por favor dir&iacute;jase al siguiente link:<br> <br> <a href='$urlSGDP'>Sistema de gesti&oacute;n documental y de procesos</a> </div> </body> </html>	0
99	URL_MANTENEDOR_AUTORES	http://192.168.1.92/sgdp/mantenedor/SGDP_AUTORES.php	0
\.


--
-- Data for Name: SGDP_PARAMETROS_ARCHIVO_NACIONAL; Type: TABLE DATA; Schema: sgdp; Owner: sgdp
--

COPY sgdp."SGDP_PARAMETROS_ARCHIVO_NACIONAL" ("ID_PARAMETRO_ARCHIVO_NACIONAL", "A_NOMBRE_PARAMETRO", "A_VALOR_PARAMETRO_CHAR", "D_FECHA_CREACION", "D_FECHA_ACTUALIZACION") FROM stdin;
\.


--
-- Data for Name: SGDP_PARAMETROS_POR_CONTEXTO; Type: TABLE DATA; Schema: sgdp; Owner: sgdp
--

COPY sgdp."SGDP_PARAMETROS_POR_CONTEXTO" ("ID_PARAMETRO_POR_CONTEXTO", "A_NOMBRE_PARAMETRO", "A_VALOR_CONTEXTO", "A_VALOR_PARAMETRO_CHAR", "N_VALOR_PARAMETRO_NUMERICO") FROM stdin;
1	MUESTRA_TAREAS_EN_EJECUCION_POR_ID_ROL	1	TODO	1
2	MUESTRA_TAREAS_EN_EJECUCION_POR_ID_ROL	4	TODO	1
3	MUESTRA_TAREAS_EN_EJECUCION_POR_ID_ROL	2	UNIDAD	1
4	TIPO_DE_DOCUMENTO_FEA_POR_MIME_TYPE_EN_CMS	application/pdf	application/pdf	1
5	CMS_SGDP_RELACION_TIPOS_DE_OBJETOS_EN_BUSQUEDA	Expedientes	CARPETA	0
6	CMS_SGDP_RELACION_TIPOS_DE_OBJETOS_EN_BUSQUEDA	Documentos	ARCHIVO	0
7	PROPOSITO_FEA	Propósito General	ATENDIDA	0
8	PROPOSITO_FEA	Desatendido	DESATENDIDA	0
9	MUESTRA_TAREAS_EN_EJECUCION_POR_ID_ROL	5	UNIDAD	1
10	MUESTRA_TAREAS_EN_EJECUCION_POR_ID_ROL	3	UNIDAD	1
11	CMS_SGDP_RELACION_TIPOS_DE_OBJETOS_EN_BUSQUEDA	Documentos Oficiales	OFICIALES	0
12	MUESTRA_TAREAS_EN_EJECUCION_POR_ID_ROL	8	UNIDAD	1
\.


--
-- Data for Name: SGDP_PARAMETRO_DE_TAREA; Type: TABLE DATA; Schema: sgdp; Owner: sgdp
--

COPY sgdp."SGDP_PARAMETRO_DE_TAREA" ("ID_PARAM_TAREA", "A_NOMBRE_PARAM_TAREA", "ID_TIPO_PARAMETRO_DE_TAREA", "A_TITULO") FROM stdin;
\.


--
-- Data for Name: SGDP_PARAMETRO_RELACION_TAREA; Type: TABLE DATA; Schema: sgdp; Owner: sgdp
--

COPY sgdp."SGDP_PARAMETRO_RELACION_TAREA" ("ID_TAREA", "ID_PARAM_TAREA") FROM stdin;
\.


--
-- Data for Name: SGDP_PERMISOS; Type: TABLE DATA; Schema: sgdp; Owner: sgdp
--

COPY sgdp."SGDP_PERMISOS" ("ID_PERMISO", "A_NOMBRE_PERMISO", "ID_ROL") FROM stdin;
1	CREAR_EXPEDIENTE	1
2	CREAR_EXPEDIENTE	2
3	SUBIR_CARTA	1
4	MODIFICA_ARCHIVOS	1
5	MODIFICA_ARCHIVOS	3
6	MODIFICA_ARCHIVOS	2
7	PUEDE_VER_TAREAS_EN_EJECUCION	1
8	PUEDE_VER_TAREAS_EN_EJECUCION	2
9	PUEDE_VER_TAREAS_EN_EJECUCION	4
10	REASIGNA_TAREA	1
11	REASIGNA_TAREA	2
12	PUEDE_VISAR_DOCUMENTO	2
13	PUEDE_VISAR_DOCUMENTO	4
14	INGRESA_DATOS_ADICIONALES_AL_SUBIR_ARCHIVO	1
15	PUEDE_FIRMAR_CON_FEA	4
16	PUEDE_FIRMAR_CON_APPLET	4
17	PUEDE_BUSCAR	1
18	PUEDE_BUSCAR	2
19	PUEDE_BUSCAR	3
20	PUEDE_BUSCAR	4
21	PUEDE_BUSCAR	5
22	PUEDE_BUSCAR	6
23	PUEDE_MANTENER_DATOS	1
24	PUEDE_MANTENER_DATOS	6
25	PUEDE_FIRMAR_CON_APPLET	2
26	PUEDE_FIRMAR_CON_FEA	2
27	PUEDE_VISAR_DOCUMENTO	3
28	INICIAR_TODOS_LOS_PROCESOS	1
29	PUEDE_VER_DASHBOARD	6
30	PUEDE_VER_MANTENEDORES	6
31	PUEDE_CERRAR_EXPEDIENTE	1
32	AUTO_ASIGNA_PRIMERA_TAREA	1
33	PUEDE_VER_TAREAS_EN_EJECUCION	5
34	NO_FILTRA_POR_CONFIDENCIALIDAD	1
35	ADJUNTAR_DOC_EN_TODA_ETAPA	1
36	PUEDE_BUSCAR	7
37	NO_FILTRA_POR_CONFIDENCIALIDAD	7
38	NO_FILTRA_POR_CONFIDENCIALIDAD	2
39	INICIAR_TODOS_LOS_PROCESOS	6
40	REASIGNA_TAREA	6
41	PUEDE_VER_TAREAS_EN_EJECUCION	6
42	PUEDE_CERRAR_EXPEDIENTE	6
43	NO_FILTRA_POR_CONFIDENCIALIDAD	6
44	AUTO_ASIGNA_PRIMERA_TAREA	6
45	ADJUNTAR_DOC_EN_TODA_ETAPA	6
46	MODIFICA_ARCHIVOS	6
47	SUBIR_CARTA	6
48	CREAR_EXPEDIENTE	6
49	INGRESA_DATOS_ADICIONALES_AL_SUBIR_ARCHIVO	6
50	PUEDE_MANTENER_NOTIFICIONES_PREDETERMINADAS	2
51	PUEDE_MANTENER_NOTIFICIONES_PREDETERMINADAS	6
52	PUEDE_MANTENER_NOTIFICIONES_PREDETERMINADAS	1
53	PUEDE_MANTENER_LISTA_DISTRIBUCION	1
54	PUEDE_VER_INDICADORES	1
55	REASIGNA_TAREA	8
56	PUEDE_VER_TAREAS_EN_EJECUCION	8
57	NO_FILTRA_POR_CONFIDENCIALIDAD	8
58	PUEDE_BUSCAR	8
59	PUEDE_VISAR_DOCUMENTO	8
60	MODIFICA_ARCHIVOS	8
61	REASIGNA_TAREA	8
62	PUEDE_MANTENER_PARAMETROS	6
63	PUEDE_REABRIR_EXPEDIENTE_Y_SATAR_TAREA	6
64	PUEDE_VINCULAR_EXPEDIENTES	1
65	PUEDE_VINCULAR_EXPEDIENTES	2
66	PUEDE_DES_VINCULAR_EXPEDIENTES	1
67	PUEDE_MANTENER_AUTORES	1
68	PUEDE_VER_MANTENEDORES	1
69	PUEDE_MANTENER_PROCESOS_SOL_CREAC_EXP	1
70	PUEDE_VINCULAR_EXPEDIENTES	5
71	CREAR_EXPEDIENTE	5
72	AUTO_ASIGNA_PRIMERA_TAREA	5
73	PUEDE_MANTENER_LISTA_DISTRIBUCION	5
74	PUEDE_FIRMAR_CON_FEA	8
75	ENVIO_ARCHIVO_NACIONAL	9
\.


--
-- Data for Name: SGDP_PERSPECTIVAS; Type: TABLE DATA; Schema: sgdp; Owner: sgdp
--

COPY sgdp."SGDP_PERSPECTIVAS" ("ID_PERSPECTIVA", "A_NOMBRE_PERSPECTIVA", "A_DESCRIPCION_PERSPECTIVA") FROM stdin;
4	Relaciones con el medio	Con usuarios industria casinos y acciones para informar a la opinión pública
3	Procesos transversales	Procesos que permiten hacer funcionar a la SCJ
2	Procesos esenciales	Procesos que se deben realizar para logarr objetivos encomendados por Ley
1	Gestión y dirección	Procesos dispuestos para gestionar y dirigir la SCJ, según facultades que entrega la Ley
\.


--
-- Data for Name: SGDP_PROCESOS; Type: TABLE DATA; Schema: sgdp; Owner: sgdp
--

COPY sgdp."SGDP_PROCESOS" ("ID_PROCESO", "A_NOMBRE_PROCESO", "A_DESCRIPCION_PROCESO", "ID_MACRO_PROCESO", "B_VIGENTE", "N_DIAS_HABILES_MAX_DURACION", "ID_UNIDAD", "B_CONFIDENCIAL", "X_BPMN", "A_CODIGO_PROCESO", "D_FECHA_CREACION") FROM stdin;
\.


--
-- Data for Name: SGDP_PROCESO_FORM_CREA_EXP; Type: TABLE DATA; Schema: sgdp; Owner: sgdp
--

COPY sgdp."SGDP_PROCESO_FORM_CREA_EXP" ("ID_PROCESO_FORM_CREA_EXP", "A_CODIGO_PROCESO", "ID_USUARIO", "D_FECHA") FROM stdin;
\.


--
-- Data for Name: SGDP_REFERENCIAS_DE_TAREAS; Type: TABLE DATA; Schema: sgdp; Owner: sgdp
--

COPY sgdp."SGDP_REFERENCIAS_DE_TAREAS" ("ID_REFERENCIA_DE_TAREA", "ID_TAREA", "ID_TAREA_SIGUIENTE") FROM stdin;
\.


--
-- Data for Name: SGDP_RESPONSABILIDAD; Type: TABLE DATA; Schema: sgdp; Owner: sgdp
--

COPY sgdp."SGDP_RESPONSABILIDAD" ("ID_RESPONSABILIDAD", "A_NOMBRE_RESPONSABILIDAD") FROM stdin;
\.


--
-- Data for Name: SGDP_RESPONSABILIDAD_TAREA; Type: TABLE DATA; Schema: sgdp; Owner: sgdp
--

COPY sgdp."SGDP_RESPONSABILIDAD_TAREA" ("ID_RESPONSABILIDAD", "ID_TAREA") FROM stdin;
\.


--
-- Data for Name: SGDP_ROLES; Type: TABLE DATA; Schema: sgdp; Owner: sgdp
--

COPY sgdp."SGDP_ROLES" ("ID_ROL", "A_NOMBRE_ROL") FROM stdin;
1	OFICINA DE PARTES
2	PROFESIONAL
3	SECRETARIA
4	JEFE DE DIVISION
5	PROFESIONAL TI
6	ANALISTA UGES
7	COORDINADOR
8	SUPERINTENDENTE(A)
9	ARCHIVO NACIONAL
\.


--
-- Data for Name: SGDP_SEGUIMIENTO_INTANCIA_PROCESOS; Type: TABLE DATA; Schema: sgdp; Owner: sgdp
--

COPY sgdp."SGDP_SEGUIMIENTO_INTANCIA_PROCESOS" ("ID_INSTANCIA_PROCESO", "ID_USUARIO", "A_TIPO_DE_NOTIFICACION") FROM stdin;
\.


--
-- Data for Name: SGDP_SOLICITUD_CREACION_EXP; Type: TABLE DATA; Schema: sgdp; Owner: sgdp
--

COPY sgdp."SGDP_SOLICITUD_CREACION_EXP" ("ID_SOLICITUD_CREACION_EXP", "ID_INSTANCIA_DE_PROCESO", "ID_USUARIO_SOLICITANTE", "ID_USUARIO_CREADOR_EXPEDIENTE", "ID_USUARIO_DESTINATARIO", "D_FECHA_SOLICITUD", "D_FECHA_ATENCION", "A_COMENTARIO", "ID_ESTADO_SOLICITUD_CREACION_EXP", "ID_PROCESO", "A_ASUNTO_MATERIA", "ID_AUTOR") FROM stdin;
\.


--
-- Data for Name: SGDP_TAREAS; Type: TABLE DATA; Schema: sgdp; Owner: sgdp
--

COPY sgdp."SGDP_TAREAS" ("ID_TAREA", "A_NOMBRE_TAREA", "A_DESCRIPCION_TAREA", "ID_PROCESO", "N_DIAS_HABILES_MAX_DURACION", "N_ORDEN", "B_VIGENTE", "B_SOLO_INFORMAR", "ID_ETAPA", "B_OBLIGATORIA", "B_ES_ULTIMA_TAREA", "A_TIPO_DE_BIFURCACION", "B_PUEDE_VISAR_DOCUMENTOS", "B_PUEDE_APLICAR_FEA", "A_URL_CONTROL", "ID_DIAGRAMA", "B_ASIGNA_NUM_DOC", "B_ESPERAR_RESP", "B_CONFORMA_EXPEDIENTE", "N_DIAS_RESETEO", "A_TIPO_RESETEO", "A_URL_WS", "B_DISTRIBUYE", "B_NUMERACION_AUTO") FROM stdin;
\.


--
-- Data for Name: SGDP_TAREAS_INICIA_PROCESOS; Type: TABLE DATA; Schema: sgdp; Owner: sgdp
--

COPY sgdp."SGDP_TAREAS_INICIA_PROCESOS" ("ID_TAREA_INICIA_PROCESO", "ID_TAREA", "ID_PROCESO") FROM stdin;
\.


--
-- Data for Name: SGDP_TAREAS_ROLES; Type: TABLE DATA; Schema: sgdp; Owner: sgdp
--

COPY sgdp."SGDP_TAREAS_ROLES" ("ID_TAREA", "ID_ROL", "N_ORDEN") FROM stdin;
\.


--
-- Data for Name: SGDP_TEXTO_PARAMETRO_DE_TAREA; Type: TABLE DATA; Schema: sgdp; Owner: sgdp
--

COPY sgdp."SGDP_TEXTO_PARAMETRO_DE_TAREA" ("ID_TEXTO_PARAMETRO_DE_TAREA", "ID_PARAM_TAREA", "A_TEXTO") FROM stdin;
\.


--
-- Data for Name: SGDP_TIPOS; Type: TABLE DATA; Schema: sgdp; Owner: sgdp
--

COPY sgdp."SGDP_TIPOS" ("ID_TIPO", "A_NOMBRE_TIPO", "D_FECHA_CREACION") FROM stdin;
1	Expediente	2021-03-19 15:54:11.368387+00
2	Documento	2021-03-19 15:54:11.368387+00
\.


--
-- Data for Name: SGDP_TIPOS_DE_DOCUMENTOS; Type: TABLE DATA; Schema: sgdp; Owner: sgdp
--

COPY sgdp."SGDP_TIPOS_DE_DOCUMENTOS" ("ID_TIPO_DE_DOCUMENTO", "A_NOMBRE_DE_TIPO_DE_DOCUMENTO", "B_CONFORMA_EXPEDIENTE", "B_APLICA_VISACION", "B_APLICA_FEA", "B_ES_DOCUMENTO_CONDUCTOR", "ID_CATEGORIA_DE_TIPO_DE_DOCUMENTO", "B_NUMERACION_AUTO", "A_COD_TIPO_DOC", "A_NOM_COMP_CAT_TIPO_DOC") FROM stdin;
\.


--
-- Data for Name: SGDP_TIPOS_DE_TAREAS_LIBRES; Type: TABLE DATA; Schema: sgdp; Owner: sgdp
--

COPY sgdp."SGDP_TIPOS_DE_TAREAS_LIBRES" ("ID_TIPO_DE_TAREA_LIBRE", "A_NOMBRE_DE_TAREA_LIBRE") FROM stdin;
\.


--
-- Data for Name: SGDP_TIPO_PARAMETRO_DE_TAREA; Type: TABLE DATA; Schema: sgdp; Owner: sgdp
--

COPY sgdp."SGDP_TIPO_PARAMETRO_DE_TAREA" ("ID_TIPO_PARAMETRO_DE_TAREA", "A_NOMBRE_TIPO_PARAMETRO_DE_TAREA", "A_TEXTO_HTML", "B_COMENTA") FROM stdin;
\.


--
-- Data for Name: SGDP_UNIDADES; Type: TABLE DATA; Schema: sgdp; Owner: sgdp
--

COPY sgdp."SGDP_UNIDADES" ("ID_UNIDAD", "A_CODIGO_UNIDAD", "A_NOMBRE_COMPLETO_UNIDAD") FROM stdin;
1	UTDP	Unidad de Tecnologia y Desarrollo de Procesos
2	DJUR	División Jurídica
3	GAB	Gabinete
4	UAYF	Unidad de Administración y Finanzas
5	DAUT	División de Autorizaciones
6	DFIS	División de Fiscalización
7	UAYC	Unidad de Atención Ciudadana y Comunicaciones
8	UAUD	Unidad de Auditoría Interna
9	COMGR	Comité de Gestión de Riesgos
10	UDE	Unidad de Estudios
11	UGEC	Unidad de Gestión Estratégica y de Clientes
12	UGIP	Unidad de Gestión Interna y Personas
13	UAIC	Unidad de Asuntos Institucionales y Comunicaciones
\.


--
-- Data for Name: SGDP_USUARIOS_ASIGNADOS_A_TAREAS; Type: TABLE DATA; Schema: sgdp; Owner: sgdp
--

COPY sgdp."SGDP_USUARIOS_ASIGNADOS_A_TAREAS" ("ID_INSTANCIA_DE_TAREA", "ID_USUARIO") FROM stdin;
\.


--
-- Data for Name: SGDP_USUARIOS_ROLES; Type: TABLE DATA; Schema: sgdp; Owner: sgdp
--

COPY sgdp."SGDP_USUARIOS_ROLES" ("ID_USUARIO_ROL", "ID_ROL", "ID_USUARIO", "ID_UNIDAD", "B_ACTIVO", "B_FUERA_DE_OFICINA", "A_NOMBRE_COMPLETO", "A_RUT") FROM stdin;
1	2	fingerhuth	3	t	f	Christian Fingerhuth	1396
\.


--
-- Data for Name: SGDP_USUARIO_NOTIFICACION_TAREA; Type: TABLE DATA; Schema: sgdp; Owner: sgdp
--

COPY sgdp."SGDP_USUARIO_NOTIFICACION_TAREA" ("ID_USUARIO_NOTIFICACION_TAREA", "ID_USUARIO", "D_FECHA_CREACION", "ID_TAREA") FROM stdin;
\.


--
-- Data for Name: SGDP_USUARIO_RESPONSABILIDAD; Type: TABLE DATA; Schema: sgdp; Owner: sgdp
--

COPY sgdp."SGDP_USUARIO_RESPONSABILIDAD" ("ID_USUARIO", "ID_RESPONSABILIDAD", "ID_USUARIO_RESPONSABILIDAD", "N_ORDEN", "B_SUBROGANDO") FROM stdin;
\.


--
-- Data for Name: SGDP_VALOR_PARAMETRO_DE_TAREA; Type: TABLE DATA; Schema: sgdp; Owner: sgdp
--

COPY sgdp."SGDP_VALOR_PARAMETRO_DE_TAREA" ("ID_VALOR_PARAMETRO_DE_TAREA", "ID_PARAM_TAREA", "ID_INSTANCIA_DE_TAREA", "A_VALOR", "D_FECHA", "A_COMENTARIO") FROM stdin;
\.


--
-- Data for Name: SGDP_VINCULACION_EXP; Type: TABLE DATA; Schema: sgdp; Owner: sgdp
--

COPY sgdp."SGDP_VINCULACION_EXP" ("ID_VINCULACION_EXP", "ID_INSTANCIA_DE_PROCESO", "ID_INSTANCIA_DE_PROCESO_ANTECESOR", "ID_USUARIO", "D_FECHA_VINCULACION", "A_COMENTARIO") FROM stdin;
\.


--
-- Name: SEQ_ID_ACCESO; Type: SEQUENCE SET; Schema: sgdp; Owner: sgdp
--

SELECT pg_catalog.setval('sgdp."SEQ_ID_ACCESO"', 3, true);


--
-- Name: SEQ_ID_ACCION_HISTORICO_INST_DE_TAREA; Type: SEQUENCE SET; Schema: sgdp; Owner: sgdp
--

SELECT pg_catalog.setval('sgdp."SEQ_ID_ACCION_HISTORICO_INST_DE_TAREA"', 1, false);


--
-- Name: SEQ_ID_ARCHIVOS_HIST_INST_DE_TAREAS; Type: SEQUENCE SET; Schema: sgdp; Owner: sgdp
--

SELECT pg_catalog.setval('sgdp."SEQ_ID_ARCHIVOS_HIST_INST_DE_TAREAS"', 1, false);


--
-- Name: SEQ_ID_ARCHIVOS_INST_DE_TAREA; Type: SEQUENCE SET; Schema: sgdp; Owner: sgdp
--

SELECT pg_catalog.setval('sgdp."SEQ_ID_ARCHIVOS_INST_DE_TAREA"', 1, false);


--
-- Name: SEQ_ID_ARCHIVOS_INST_DE_TAREA_METADATA; Type: SEQUENCE SET; Schema: sgdp; Owner: sgdp
--

SELECT pg_catalog.setval('sgdp."SEQ_ID_ARCHIVOS_INST_DE_TAREA_METADATA"', 1, false);


--
-- Name: SEQ_ID_ASIGNACION_NUMERO_DOC; Type: SEQUENCE SET; Schema: sgdp; Owner: sgdp
--

SELECT pg_catalog.setval('sgdp."SEQ_ID_ASIGNACION_NUMERO_DOC"', 1, false);


--
-- Name: SEQ_ID_AUTOR; Type: SEQUENCE SET; Schema: sgdp; Owner: sgdp
--

SELECT pg_catalog.setval('sgdp."SEQ_ID_AUTOR"', 6, true);


--
-- Name: SEQ_ID_CARGA; Type: SEQUENCE SET; Schema: sgdp; Owner: sgdp
--

SELECT pg_catalog.setval('sgdp."SEQ_ID_CARGA"', 1, false);


--
-- Name: SEQ_ID_CARGO; Type: SEQUENCE SET; Schema: sgdp; Owner: sgdp
--

SELECT pg_catalog.setval('sgdp."SEQ_ID_CARGO"', 3, false);


--
-- Name: SEQ_ID_CATEGORIA_DE_TIPO_DE_DOCUMENTO; Type: SEQUENCE SET; Schema: sgdp; Owner: sgdp
--

SELECT pg_catalog.setval('sgdp."SEQ_ID_CATEGORIA_DE_TIPO_DE_DOCUMENTO"', 1, false);


--
-- Name: SEQ_ID_COMENT_HIST_INST_DE_TAREAS; Type: SEQUENCE SET; Schema: sgdp; Owner: sgdp
--

SELECT pg_catalog.setval('sgdp."SEQ_ID_COMENT_HIST_INST_DE_TAREAS"', 1, false);


--
-- Name: SEQ_ID_DETALLE_CARGA; Type: SEQUENCE SET; Schema: sgdp; Owner: sgdp
--

SELECT pg_catalog.setval('sgdp."SEQ_ID_DETALLE_CARGA"', 1, false);


--
-- Name: SEQ_ID_DOCUMENTO; Type: SEQUENCE SET; Schema: sgdp; Owner: sgdp
--

SELECT pg_catalog.setval('sgdp."SEQ_ID_DOCUMENTO"', 1, false);


--
-- Name: SEQ_ID_ESTADO_DE_PROCESO; Type: SEQUENCE SET; Schema: sgdp; Owner: sgdp
--

SELECT pg_catalog.setval('sgdp."SEQ_ID_ESTADO_DE_PROCESO"', 4, true);


--
-- Name: SEQ_ID_ESTADO_DE_TAREA; Type: SEQUENCE SET; Schema: sgdp; Owner: sgdp
--

SELECT pg_catalog.setval('sgdp."SEQ_ID_ESTADO_DE_TAREA"', 4, true);


--
-- Name: SEQ_ID_ESTADO_SOLICITUD_CREACION_EXP; Type: SEQUENCE SET; Schema: sgdp; Owner: sgdp
--

SELECT pg_catalog.setval('sgdp."SEQ_ID_ESTADO_SOLICITUD_CREACION_EXP"', 5, true);


--
-- Name: SEQ_ID_ETAPA; Type: SEQUENCE SET; Schema: sgdp; Owner: sgdp
--

SELECT pg_catalog.setval('sgdp."SEQ_ID_ETAPA"', 8, true);


--
-- Name: SEQ_ID_EXPEDIENTE; Type: SEQUENCE SET; Schema: sgdp; Owner: sgdp
--

SELECT pg_catalog.setval('sgdp."SEQ_ID_EXPEDIENTE"', 1, false);


--
-- Name: SEQ_ID_HISTORICO_ARCHIVOS_INST_DE_TAREAS; Type: SEQUENCE SET; Schema: sgdp; Owner: sgdp
--

SELECT pg_catalog.setval('sgdp."SEQ_ID_HISTORICO_ARCHIVOS_INST_DE_TAREAS"', 1, false);


--
-- Name: SEQ_ID_HISTORICO_DE_INST_DE_TAREA; Type: SEQUENCE SET; Schema: sgdp; Owner: sgdp
--

SELECT pg_catalog.setval('sgdp."SEQ_ID_HISTORICO_DE_INST_DE_TAREA"', 1, false);


--
-- Name: SEQ_ID_HISTORICO_FIRMA; Type: SEQUENCE SET; Schema: sgdp; Owner: sgdp
--

SELECT pg_catalog.setval('sgdp."SEQ_ID_HISTORICO_FIRMA"', 1, false);


--
-- Name: SEQ_ID_HISTORICO_SOLICITUD_CREACION_EXP; Type: SEQUENCE SET; Schema: sgdp; Owner: sgdp
--

SELECT pg_catalog.setval('sgdp."SEQ_ID_HISTORICO_SOLICITUD_CREACION_EXP"', 1, false);


--
-- Name: SEQ_ID_HISTORICO_VALOR_PARAMETRO_DE_TAREA; Type: SEQUENCE SET; Schema: sgdp; Owner: sgdp
--

SELECT pg_catalog.setval('sgdp."SEQ_ID_HISTORICO_VALOR_PARAMETRO_DE_TAREA"', 1, false);


--
-- Name: SEQ_ID_HISTORICO_VINCULACION_EXP; Type: SEQUENCE SET; Schema: sgdp; Owner: sgdp
--

SELECT pg_catalog.setval('sgdp."SEQ_ID_HISTORICO_VINCULACION_EXP"', 1, false);


--
-- Name: SEQ_ID_HIST_FECHA_VENC_INS_PROC; Type: SEQUENCE SET; Schema: sgdp; Owner: sgdp
--

SELECT pg_catalog.setval('sgdp."SEQ_ID_HIST_FECHA_VENC_INS_PROC"', 1, false);


--
-- Name: SEQ_ID_INSTANCIA_DE_PROCESO; Type: SEQUENCE SET; Schema: sgdp; Owner: sgdp
--

SELECT pg_catalog.setval('sgdp."SEQ_ID_INSTANCIA_DE_PROCESO"', 1, false);


--
-- Name: SEQ_ID_INSTANCIA_DE_TAREA; Type: SEQUENCE SET; Schema: sgdp; Owner: sgdp
--

SELECT pg_catalog.setval('sgdp."SEQ_ID_INSTANCIA_DE_TAREA"', 1000, false);


--
-- Name: SEQ_ID_INSTANCIA_DE_TAREA_LIBRE; Type: SEQUENCE SET; Schema: sgdp; Owner: sgdp
--

SELECT pg_catalog.setval('sgdp."SEQ_ID_INSTANCIA_DE_TAREA_LIBRE"', 1, false);


--
-- Name: SEQ_ID_INSTANCIA_PROCESO_METADATA; Type: SEQUENCE SET; Schema: sgdp; Owner: sgdp
--

SELECT pg_catalog.setval('sgdp."SEQ_ID_INSTANCIA_PROCESO_METADATA"', 1, false);


--
-- Name: SEQ_ID_LISTA_DE_DISTRIBUCION; Type: SEQUENCE SET; Schema: sgdp; Owner: sgdp
--

SELECT pg_catalog.setval('sgdp."SEQ_ID_LISTA_DE_DISTRIBUCION"', 1, false);


--
-- Name: SEQ_ID_LOG_CARGA; Type: SEQUENCE SET; Schema: sgdp; Owner: sgdp
--

SELECT pg_catalog.setval('sgdp."SEQ_ID_LOG_CARGA"', 1, false);


--
-- Name: SEQ_ID_LOG_ERROR; Type: SEQUENCE SET; Schema: sgdp; Owner: sgdp
--

SELECT pg_catalog.setval('sgdp."SEQ_ID_LOG_ERROR"', 1, false);


--
-- Name: SEQ_ID_LOG_FUERA_DE_OFICINA; Type: SEQUENCE SET; Schema: sgdp; Owner: sgdp
--

SELECT pg_catalog.setval('sgdp."SEQ_ID_LOG_FUERA_DE_OFICINA"', 2594, false);


--
-- Name: SEQ_ID_LOG_TRANSACCION; Type: SEQUENCE SET; Schema: sgdp; Owner: sgdp
--

SELECT pg_catalog.setval('sgdp."SEQ_ID_LOG_TRANSACCION"', 1, false);


--
-- Name: SEQ_ID_MACRO_PROCESO; Type: SEQUENCE SET; Schema: sgdp; Owner: sgdp
--

SELECT pg_catalog.setval('sgdp."SEQ_ID_MACRO_PROCESO"', 1, false);


--
-- Name: SEQ_ID_PARAMETRO; Type: SEQUENCE SET; Schema: sgdp; Owner: sgdp
--

SELECT pg_catalog.setval('sgdp."SEQ_ID_PARAMETRO"', 1, false);


--
-- Name: SEQ_ID_PARAMETRO_ARCHIVO_NACIONAL; Type: SEQUENCE SET; Schema: sgdp; Owner: sgdp
--

SELECT pg_catalog.setval('sgdp."SEQ_ID_PARAMETRO_ARCHIVO_NACIONAL"', 1, false);


--
-- Name: SEQ_ID_PARAMETRO_POR_CONTEXTO; Type: SEQUENCE SET; Schema: sgdp; Owner: sgdp
--

SELECT pg_catalog.setval('sgdp."SEQ_ID_PARAMETRO_POR_CONTEXTO"', 12, true);


--
-- Name: SEQ_ID_PARAM_TAREA; Type: SEQUENCE SET; Schema: sgdp; Owner: sgdp
--

SELECT pg_catalog.setval('sgdp."SEQ_ID_PARAM_TAREA"', 4, false);


--
-- Name: SEQ_ID_PERMISO; Type: SEQUENCE SET; Schema: sgdp; Owner: sgdp
--

SELECT pg_catalog.setval('sgdp."SEQ_ID_PERMISO"', 75, true);


--
-- Name: SEQ_ID_PERSPECTIVA; Type: SEQUENCE SET; Schema: sgdp; Owner: sgdp
--

SELECT pg_catalog.setval('sgdp."SEQ_ID_PERSPECTIVA"', 1, false);


--
-- Name: SEQ_ID_PROCESO; Type: SEQUENCE SET; Schema: sgdp; Owner: sgdp
--

SELECT pg_catalog.setval('sgdp."SEQ_ID_PROCESO"', 1, false);


--
-- Name: SEQ_ID_PROCESO_FORM_CREA_EXP; Type: SEQUENCE SET; Schema: sgdp; Owner: sgdp
--

SELECT pg_catalog.setval('sgdp."SEQ_ID_PROCESO_FORM_CREA_EXP"', 1, false);


--
-- Name: SEQ_ID_REFERENCIA_DE_TAREA; Type: SEQUENCE SET; Schema: sgdp; Owner: sgdp
--

SELECT pg_catalog.setval('sgdp."SEQ_ID_REFERENCIA_DE_TAREA"', 1, false);


--
-- Name: SEQ_ID_RESPONSABILIDAD; Type: SEQUENCE SET; Schema: sgdp; Owner: sgdp
--

SELECT pg_catalog.setval('sgdp."SEQ_ID_RESPONSABILIDAD"', 1, false);


--
-- Name: SEQ_ID_ROL; Type: SEQUENCE SET; Schema: sgdp; Owner: sgdp
--

SELECT pg_catalog.setval('sgdp."SEQ_ID_ROL"', 8, true);


--
-- Name: SEQ_ID_SOLICITUD_CREACION_EXP; Type: SEQUENCE SET; Schema: sgdp; Owner: sgdp
--

SELECT pg_catalog.setval('sgdp."SEQ_ID_SOLICITUD_CREACION_EXP"', 1, false);


--
-- Name: SEQ_ID_TAREA; Type: SEQUENCE SET; Schema: sgdp; Owner: sgdp
--

SELECT pg_catalog.setval('sgdp."SEQ_ID_TAREA"', 1, false);


--
-- Name: SEQ_ID_TAREA_INICIA_PROCESO; Type: SEQUENCE SET; Schema: sgdp; Owner: sgdp
--

SELECT pg_catalog.setval('sgdp."SEQ_ID_TAREA_INICIA_PROCESO"', 1, false);


--
-- Name: SEQ_ID_TEXTO_PARAMETRO_DE_TAREA; Type: SEQUENCE SET; Schema: sgdp; Owner: sgdp
--

SELECT pg_catalog.setval('sgdp."SEQ_ID_TEXTO_PARAMETRO_DE_TAREA"', 1, false);


--
-- Name: SEQ_ID_TIPO; Type: SEQUENCE SET; Schema: sgdp; Owner: sgdp
--

SELECT pg_catalog.setval('sgdp."SEQ_ID_TIPO"', 1, false);


--
-- Name: SEQ_ID_TIPO_DE_DOCUMENTO; Type: SEQUENCE SET; Schema: sgdp; Owner: sgdp
--

SELECT pg_catalog.setval('sgdp."SEQ_ID_TIPO_DE_DOCUMENTO"', 1, false);


--
-- Name: SEQ_ID_TIPO_DE_TAREA_LIBRE; Type: SEQUENCE SET; Schema: sgdp; Owner: sgdp
--

SELECT pg_catalog.setval('sgdp."SEQ_ID_TIPO_DE_TAREA_LIBRE"', 1, false);


--
-- Name: SEQ_ID_TIPO_PARAMETRO_DE_TAREA; Type: SEQUENCE SET; Schema: sgdp; Owner: sgdp
--

SELECT pg_catalog.setval('sgdp."SEQ_ID_TIPO_PARAMETRO_DE_TAREA"', 1, false);


--
-- Name: SEQ_ID_UNIDAD; Type: SEQUENCE SET; Schema: sgdp; Owner: sgdp
--

SELECT pg_catalog.setval('sgdp."SEQ_ID_UNIDAD"', 13, true);


--
-- Name: SEQ_ID_USUARIO_RESPONSABILIDAD; Type: SEQUENCE SET; Schema: sgdp; Owner: sgdp
--

SELECT pg_catalog.setval('sgdp."SEQ_ID_USUARIO_RESPONSABILIDAD"', 1, false);


--
-- Name: SEQ_ID_USUARIO_ROL; Type: SEQUENCE SET; Schema: sgdp; Owner: sgdp
--

SELECT pg_catalog.setval('sgdp."SEQ_ID_USUARIO_ROL"', 1, true);


--
-- Name: SEQ_ID_VALOR_PARAMETRO_DE_TAREA; Type: SEQUENCE SET; Schema: sgdp; Owner: sgdp
--

SELECT pg_catalog.setval('sgdp."SEQ_ID_VALOR_PARAMETRO_DE_TAREA"', 1, false);


--
-- Name: SEQ_ID_VINCULACION_EXP; Type: SEQUENCE SET; Schema: sgdp; Owner: sgdp
--

SELECT pg_catalog.setval('sgdp."SEQ_ID_VINCULACION_EXP"', 1, false);


--
-- Name: SEQ_NOMBRE_ID_EXPEDIENTE; Type: SEQUENCE SET; Schema: sgdp; Owner: sgdp
--

SELECT pg_catalog.setval('sgdp."SEQ_NOMBRE_ID_EXPEDIENTE"', 1, false);


--
-- Name: SGDP_HISTORIAL_SEGUIMIENTO_IN_ID_HISTORICO_INSTANCIA_PROCES_seq; Type: SEQUENCE SET; Schema: sgdp; Owner: sgdp
--

SELECT pg_catalog.setval('sgdp."SGDP_HISTORIAL_SEGUIMIENTO_IN_ID_HISTORICO_INSTANCIA_PROCES_seq"', 1, false);


--
-- Name: SGDP_USUARIO_NOTIFICACION_TAR_ID_USUARIO_NOTIFICACION_TAREA_seq; Type: SEQUENCE SET; Schema: sgdp; Owner: sgdp
--

SELECT pg_catalog.setval('sgdp."SGDP_USUARIO_NOTIFICACION_TAR_ID_USUARIO_NOTIFICACION_TAREA_seq"', 1, false);


--
-- Name: SGDP_USUARIO_NOTIFICACION_TAR_ID_USUARIO_NOTIFI_TAREA_seq2; Type: SEQUENCE SET; Schema: sgdp; Owner: sgdp
--

SELECT pg_catalog.setval('sgdp."SGDP_USUARIO_NOTIFICACION_TAR_ID_USUARIO_NOTIFI_TAREA_seq2"', 77, false);


--
-- Name: SGDP_HISTORICO_FECHA_VENC_INS_PROC PK01_ID_HIST_FECHA_VENC_INS_PROC; Type: CONSTRAINT; Schema: sgdp; Owner: sgdp
--

ALTER TABLE ONLY sgdp."SGDP_HISTORICO_FECHA_VENC_INS_PROC"
    ADD CONSTRAINT "PK01_ID_HIST_FECHA_VENC_INS_PROC" UNIQUE ("ID_HIST_FECHA_VENC_INS_PROC");


--
-- Name: SGDP_ACCESOS PK_ACCESO; Type: CONSTRAINT; Schema: sgdp; Owner: sgdp
--

ALTER TABLE ONLY sgdp."SGDP_ACCESOS"
    ADD CONSTRAINT "PK_ACCESO" PRIMARY KEY ("ID_ACCESO");


--
-- Name: SGDP_ACCIONES_HIST_INST_DE_TAREAS PK_ACCIONES_HIST_INST_DE_TAREAS; Type: CONSTRAINT; Schema: sgdp; Owner: sgdp
--

ALTER TABLE ONLY sgdp."SGDP_ACCIONES_HIST_INST_DE_TAREAS"
    ADD CONSTRAINT "PK_ACCIONES_HIST_INST_DE_TAREAS" PRIMARY KEY ("ID_ACCION_HISTORICO_INST_DE_TAREA");


--
-- Name: SGDP_ARCHIVOS_INST_DE_TAREA PK_ARCHIVOS_INST_DE_TAREA; Type: CONSTRAINT; Schema: sgdp; Owner: sgdp
--

ALTER TABLE ONLY sgdp."SGDP_ARCHIVOS_INST_DE_TAREA"
    ADD CONSTRAINT "PK_ARCHIVOS_INST_DE_TAREA" PRIMARY KEY ("ID_ARCHIVOS_INST_DE_TAREA");


--
-- Name: SGDP_AUTORES PK_AUTORES; Type: CONSTRAINT; Schema: sgdp; Owner: sgdp
--

ALTER TABLE ONLY sgdp."SGDP_AUTORES"
    ADD CONSTRAINT "PK_AUTORES" PRIMARY KEY ("ID_AUTOR");


--
-- Name: SGDP_CARGAS PK_CARGA; Type: CONSTRAINT; Schema: sgdp; Owner: sgdp
--

ALTER TABLE ONLY sgdp."SGDP_CARGAS"
    ADD CONSTRAINT "PK_CARGA" PRIMARY KEY ("ID_CARGA");


--
-- Name: SGDP_CATEGORIA_DE_TIPO_DE_DOCUMENTO PK_CATEGORIA_DE_TIPO_DE_DOCUMENTO; Type: CONSTRAINT; Schema: sgdp; Owner: sgdp
--

ALTER TABLE ONLY sgdp."SGDP_CATEGORIA_DE_TIPO_DE_DOCUMENTO"
    ADD CONSTRAINT "PK_CATEGORIA_DE_TIPO_DE_DOCUMENTO" PRIMARY KEY ("ID_CATEGORIA_DE_TIPO_DE_DOCUMENTO");


--
-- Name: SGDP_DETALLES_CARGA PK_DETALLE_CARGA; Type: CONSTRAINT; Schema: sgdp; Owner: sgdp
--

ALTER TABLE ONLY sgdp."SGDP_DETALLES_CARGA"
    ADD CONSTRAINT "PK_DETALLE_CARGA" PRIMARY KEY ("ID_DETALLE_CARGA");


--
-- Name: SGDP_DOCUMENTOS_DE_SALIDA_DE_TAREAS PK_DOCUMENTOS_DE_SALIDA_DE_TAREAS; Type: CONSTRAINT; Schema: sgdp; Owner: sgdp
--

ALTER TABLE ONLY sgdp."SGDP_DOCUMENTOS_DE_SALIDA_DE_TAREAS"
    ADD CONSTRAINT "PK_DOCUMENTOS_DE_SALIDA_DE_TAREAS" PRIMARY KEY ("ID_TAREA", "ID_TIPO_DE_DOCUMENTO");


--
-- Name: SGDP_ESTADOS_DE_PROCESOS PK_ESTADOS_DE_PROCESOS; Type: CONSTRAINT; Schema: sgdp; Owner: sgdp
--

ALTER TABLE ONLY sgdp."SGDP_ESTADOS_DE_PROCESOS"
    ADD CONSTRAINT "PK_ESTADOS_DE_PROCESOS" PRIMARY KEY ("ID_ESTADO_DE_PROCESO");


--
-- Name: SGDP_ESTADOS_DE_TAREAS PK_ESTADOS_DE_TAREAS; Type: CONSTRAINT; Schema: sgdp; Owner: sgdp
--

ALTER TABLE ONLY sgdp."SGDP_ESTADOS_DE_TAREAS"
    ADD CONSTRAINT "PK_ESTADOS_DE_TAREAS" PRIMARY KEY ("ID_ESTADO_DE_TAREA");


--
-- Name: SGDP_ESTADO_SOLICITUD_CREACION_EXP PK_ESTADO_SOLICITUD_CREACION_EXP; Type: CONSTRAINT; Schema: sgdp; Owner: sgdp
--

ALTER TABLE ONLY sgdp."SGDP_ESTADO_SOLICITUD_CREACION_EXP"
    ADD CONSTRAINT "PK_ESTADO_SOLICITUD_CREACION_EXP" PRIMARY KEY ("ID_ESTADO_SOLICITUD_CREACION_EXP");


--
-- Name: SGDP_ETAPAS PK_ETAPAS; Type: CONSTRAINT; Schema: sgdp; Owner: sgdp
--

ALTER TABLE ONLY sgdp."SGDP_ETAPAS"
    ADD CONSTRAINT "PK_ETAPAS" PRIMARY KEY ("ID_ETAPA");


--
-- Name: SGDP_TEXTO_PARAMETRO_DE_TAREA PK_EXTO_PARAMETRO_DE_TAREA; Type: CONSTRAINT; Schema: sgdp; Owner: sgdp
--

ALTER TABLE ONLY sgdp."SGDP_TEXTO_PARAMETRO_DE_TAREA"
    ADD CONSTRAINT "PK_EXTO_PARAMETRO_DE_TAREA" PRIMARY KEY ("ID_TEXTO_PARAMETRO_DE_TAREA");


--
-- Name: SGDP_FECHAS_FERIADOS PK_FECHAS_FERIADOS; Type: CONSTRAINT; Schema: sgdp; Owner: sgdp
--

ALTER TABLE ONLY sgdp."SGDP_FECHAS_FERIADOS"
    ADD CONSTRAINT "PK_FECHAS_FERIADOS" PRIMARY KEY ("A_FECHA_FERIADO");


--
-- Name: SGDP_HISTORICO_ACCIONES_INST_DE_TAREAS PK_HISTORICO_ACCIONES_INST_DE_TAREAS; Type: CONSTRAINT; Schema: sgdp; Owner: sgdp
--

ALTER TABLE ONLY sgdp."SGDP_HISTORICO_ACCIONES_INST_DE_TAREAS"
    ADD CONSTRAINT "PK_HISTORICO_ACCIONES_INST_DE_TAREAS" PRIMARY KEY ("ID_HISTORICO_ACCIONES_INST_DE_TAREAS");


--
-- Name: SGDP_HISTORICO_ARCHIVOS_INST_DE_TAREAS PK_HISTORICO_ARCHIVOS_INST_DE_TAREAS; Type: CONSTRAINT; Schema: sgdp; Owner: sgdp
--

ALTER TABLE ONLY sgdp."SGDP_HISTORICO_ARCHIVOS_INST_DE_TAREAS"
    ADD CONSTRAINT "PK_HISTORICO_ARCHIVOS_INST_DE_TAREAS" PRIMARY KEY ("ID_HISTORICO_ARCHIVOS_INST_DE_TAREAS");


--
-- Name: SGDP_HISTORICO_DE_INST_DE_TAREAS PK_HISTORICO_DE_INST_DE_TAREAS; Type: CONSTRAINT; Schema: sgdp; Owner: sgdp
--

ALTER TABLE ONLY sgdp."SGDP_HISTORICO_DE_INST_DE_TAREAS"
    ADD CONSTRAINT "PK_HISTORICO_DE_INST_DE_TAREAS" PRIMARY KEY ("ID_HISTORICO_DE_INST_DE_TAREA");


--
-- Name: SGDP_HISTORICO_SOLICITUD_CREACION_EXP PK_HISTORICO_SOLICITUD_CREACION_EXP; Type: CONSTRAINT; Schema: sgdp; Owner: sgdp
--

ALTER TABLE ONLY sgdp."SGDP_HISTORICO_SOLICITUD_CREACION_EXP"
    ADD CONSTRAINT "PK_HISTORICO_SOLICITUD_CREACION_EXP" PRIMARY KEY ("ID_HISTORICO_SOLICITUD_CREACION_EXP");


--
-- Name: SGDP_HISTORICO_USUARIOS_ASIGNADOS_A_TAREAS PK_HISTORICO_USUARIOS_ASIGNADOS_A_TAREAS; Type: CONSTRAINT; Schema: sgdp; Owner: sgdp
--

ALTER TABLE ONLY sgdp."SGDP_HISTORICO_USUARIOS_ASIGNADOS_A_TAREAS"
    ADD CONSTRAINT "PK_HISTORICO_USUARIOS_ASIGNADOS_A_TAREAS" PRIMARY KEY ("ID_HISTORICO_DE_INST_DE_TAREA", "ID_USUARIO");


--
-- Name: SGDP_HISTORICO_VALOR_PARAMETRO_DE_TAREA PK_HISTORICO_VALOR_PARAMETRO_DE_TAREA; Type: CONSTRAINT; Schema: sgdp; Owner: sgdp
--

ALTER TABLE ONLY sgdp."SGDP_HISTORICO_VALOR_PARAMETRO_DE_TAREA"
    ADD CONSTRAINT "PK_HISTORICO_VALOR_PARAMETRO_DE_TAREA" PRIMARY KEY ("ID_HISTORICO_VALOR_PARAMETRO_DE_TAREA");


--
-- Name: SGDP_HISTORICO_VINCULACION_EXP PK_HISTORICO_VINCULACION_EXP; Type: CONSTRAINT; Schema: sgdp; Owner: sgdp
--

ALTER TABLE ONLY sgdp."SGDP_HISTORICO_VINCULACION_EXP"
    ADD CONSTRAINT "PK_HISTORICO_VINCULACION_EXP" PRIMARY KEY ("ID_HISTORICO_VINCULACION_EXP");


--
-- Name: SGDP_INSTANCIAS_DE_TAREAS PK_INSTANCIAS_DE_TAREAS; Type: CONSTRAINT; Schema: sgdp; Owner: sgdp
--

ALTER TABLE ONLY sgdp."SGDP_INSTANCIAS_DE_TAREAS"
    ADD CONSTRAINT "PK_INSTANCIAS_DE_TAREAS" PRIMARY KEY ("ID_INSTANCIA_DE_TAREA");


--
-- Name: SGDP_INSTANCIAS_DE_TAREAS_LIBRES PK_INSTANCIAS_DE_TAREAS_LIBRES; Type: CONSTRAINT; Schema: sgdp; Owner: sgdp
--

ALTER TABLE ONLY sgdp."SGDP_INSTANCIAS_DE_TAREAS_LIBRES"
    ADD CONSTRAINT "PK_INSTANCIAS_DE_TAREAS_LIBRES" PRIMARY KEY ("ID_INSTANCIA_DE_TAREA_LIBRE");


--
-- Name: SGDP_ARCHIVOS_INST_DE_TAREA_METADATA PK_INSTANCIAS_DE_TAREAS_METADATA; Type: CONSTRAINT; Schema: sgdp; Owner: sgdp
--

ALTER TABLE ONLY sgdp."SGDP_ARCHIVOS_INST_DE_TAREA_METADATA"
    ADD CONSTRAINT "PK_INSTANCIAS_DE_TAREAS_METADATA" PRIMARY KEY ("ID_ARCHIVOS_INST_DE_TAREA_METADATA");


--
-- Name: SGDP_INSTANCIA_PROCESO_METADATA PK_INSTANCIA_PROCESO_METADATA; Type: CONSTRAINT; Schema: sgdp; Owner: sgdp
--

ALTER TABLE ONLY sgdp."SGDP_INSTANCIA_PROCESO_METADATA"
    ADD CONSTRAINT "PK_INSTANCIA_PROCESO_METADATA" PRIMARY KEY ("ID_INSTANCIA_PROCESO_METADATA");


--
-- Name: SGDP_LOG_CARGA PK_LOG_CARGA; Type: CONSTRAINT; Schema: sgdp; Owner: sgdp
--

ALTER TABLE ONLY sgdp."SGDP_LOG_CARGA"
    ADD CONSTRAINT "PK_LOG_CARGA" PRIMARY KEY ("ID_LOG_CARGA");


--
-- Name: SGDP_LOG_ERROR PK_LOG_ERROR; Type: CONSTRAINT; Schema: sgdp; Owner: sgdp
--

ALTER TABLE ONLY sgdp."SGDP_LOG_ERROR"
    ADD CONSTRAINT "PK_LOG_ERROR" PRIMARY KEY ("ID_LOG_ERROR");


--
-- Name: SGDP_LOG_TRANSACCIONES PK_LOG_TRANSACCIONES; Type: CONSTRAINT; Schema: sgdp; Owner: sgdp
--

ALTER TABLE ONLY sgdp."SGDP_LOG_TRANSACCIONES"
    ADD CONSTRAINT "PK_LOG_TRANSACCIONES" PRIMARY KEY ("ID_LOG_TRANSACCION");


--
-- Name: SGDP_MACRO_PROCESOS PK_MACRO_PROCESOS; Type: CONSTRAINT; Schema: sgdp; Owner: sgdp
--

ALTER TABLE ONLY sgdp."SGDP_MACRO_PROCESOS"
    ADD CONSTRAINT "PK_MACRO_PROCESOS" PRIMARY KEY ("ID_MACRO_PROCESO");


--
-- Name: SGDP_PARAMETROS PK_PARAMETROS; Type: CONSTRAINT; Schema: sgdp; Owner: sgdp
--

ALTER TABLE ONLY sgdp."SGDP_PARAMETROS"
    ADD CONSTRAINT "PK_PARAMETROS" PRIMARY KEY ("ID_PARAMETRO");


--
-- Name: SGDP_PARAMETROS_POR_CONTEXTO PK_PARAMETROS_POR_CONTEXTO; Type: CONSTRAINT; Schema: sgdp; Owner: sgdp
--

ALTER TABLE ONLY sgdp."SGDP_PARAMETROS_POR_CONTEXTO"
    ADD CONSTRAINT "PK_PARAMETROS_POR_CONTEXTO" PRIMARY KEY ("ID_PARAMETRO_POR_CONTEXTO");


--
-- Name: SGDP_PARAMETROS_ARCHIVO_NACIONAL PK_PARAMETRO_ARCHIVO_NACIONAL; Type: CONSTRAINT; Schema: sgdp; Owner: sgdp
--

ALTER TABLE ONLY sgdp."SGDP_PARAMETROS_ARCHIVO_NACIONAL"
    ADD CONSTRAINT "PK_PARAMETRO_ARCHIVO_NACIONAL" PRIMARY KEY ("ID_PARAMETRO_ARCHIVO_NACIONAL");


--
-- Name: SGDP_PARAMETRO_DE_TAREA PK_PARAMETRO_DE_TAREA; Type: CONSTRAINT; Schema: sgdp; Owner: sgdp
--

ALTER TABLE ONLY sgdp."SGDP_PARAMETRO_DE_TAREA"
    ADD CONSTRAINT "PK_PARAMETRO_DE_TAREA" PRIMARY KEY ("ID_PARAM_TAREA");


--
-- Name: SGDP_PARAMETRO_RELACION_TAREA PK_PARAMETRO_RELACION_TAREA; Type: CONSTRAINT; Schema: sgdp; Owner: sgdp
--

ALTER TABLE ONLY sgdp."SGDP_PARAMETRO_RELACION_TAREA"
    ADD CONSTRAINT "PK_PARAMETRO_RELACION_TAREA" PRIMARY KEY ("ID_TAREA", "ID_PARAM_TAREA");


--
-- Name: SGDP_PERMISOS PK_PERMISOS; Type: CONSTRAINT; Schema: sgdp; Owner: sgdp
--

ALTER TABLE ONLY sgdp."SGDP_PERMISOS"
    ADD CONSTRAINT "PK_PERMISOS" PRIMARY KEY ("ID_PERMISO");


--
-- Name: SGDP_PERSPECTIVAS PK_PERSPECTIVAS; Type: CONSTRAINT; Schema: sgdp; Owner: sgdp
--

ALTER TABLE ONLY sgdp."SGDP_PERSPECTIVAS"
    ADD CONSTRAINT "PK_PERSPECTIVAS" PRIMARY KEY ("ID_PERSPECTIVA");


--
-- Name: SGDP_PROCESOS PK_PROCESOS; Type: CONSTRAINT; Schema: sgdp; Owner: sgdp
--

ALTER TABLE ONLY sgdp."SGDP_PROCESOS"
    ADD CONSTRAINT "PK_PROCESOS" PRIMARY KEY ("ID_PROCESO");


--
-- Name: SGDP_PROCESO_FORM_CREA_EXP PK_PROCESO_FORM_CREA_EXP; Type: CONSTRAINT; Schema: sgdp; Owner: sgdp
--

ALTER TABLE ONLY sgdp."SGDP_PROCESO_FORM_CREA_EXP"
    ADD CONSTRAINT "PK_PROCESO_FORM_CREA_EXP" PRIMARY KEY ("ID_PROCESO_FORM_CREA_EXP");


--
-- Name: SGDP_REFERENCIAS_DE_TAREAS PK_REFERENCIAS_DE_TAREAS; Type: CONSTRAINT; Schema: sgdp; Owner: sgdp
--

ALTER TABLE ONLY sgdp."SGDP_REFERENCIAS_DE_TAREAS"
    ADD CONSTRAINT "PK_REFERENCIAS_DE_TAREAS" PRIMARY KEY ("ID_REFERENCIA_DE_TAREA");


--
-- Name: SGDP_ROLES PK_ROLES; Type: CONSTRAINT; Schema: sgdp; Owner: sgdp
--

ALTER TABLE ONLY sgdp."SGDP_ROLES"
    ADD CONSTRAINT "PK_ROLES" PRIMARY KEY ("ID_ROL");


--
-- Name: SGDP_CARGO PK_SGDP_CARGO; Type: CONSTRAINT; Schema: sgdp; Owner: sgdp
--

ALTER TABLE ONLY sgdp."SGDP_CARGO"
    ADD CONSTRAINT "PK_SGDP_CARGO" UNIQUE ("ID_CARGO");


--
-- Name: SGDP_INSTANCIAS_DE_PROCESOS PK_SGDP_INSTANCIAS_DE_PROCESOS; Type: CONSTRAINT; Schema: sgdp; Owner: sgdp
--

ALTER TABLE ONLY sgdp."SGDP_INSTANCIAS_DE_PROCESOS"
    ADD CONSTRAINT "PK_SGDP_INSTANCIAS_DE_PROCESOS" PRIMARY KEY ("ID_INSTANCIA_DE_PROCESO");


--
-- Name: SGDP_SOLICITUD_CREACION_EXP PK_SOLICITUD_CREACION_EXP; Type: CONSTRAINT; Schema: sgdp; Owner: sgdp
--

ALTER TABLE ONLY sgdp."SGDP_SOLICITUD_CREACION_EXP"
    ADD CONSTRAINT "PK_SOLICITUD_CREACION_EXP" PRIMARY KEY ("ID_SOLICITUD_CREACION_EXP");


--
-- Name: SGDP_TAREAS PK_TAREAS; Type: CONSTRAINT; Schema: sgdp; Owner: sgdp
--

ALTER TABLE ONLY sgdp."SGDP_TAREAS"
    ADD CONSTRAINT "PK_TAREAS" PRIMARY KEY ("ID_TAREA");


--
-- Name: SGDP_TAREAS_INICIA_PROCESOS PK_TAREAS_INICIA_PROCESOS; Type: CONSTRAINT; Schema: sgdp; Owner: sgdp
--

ALTER TABLE ONLY sgdp."SGDP_TAREAS_INICIA_PROCESOS"
    ADD CONSTRAINT "PK_TAREAS_INICIA_PROCESOS" PRIMARY KEY ("ID_TAREA_INICIA_PROCESO");


--
-- Name: SGDP_TAREAS_ROLES PK_TAREAS_ROLES; Type: CONSTRAINT; Schema: sgdp; Owner: sgdp
--

ALTER TABLE ONLY sgdp."SGDP_TAREAS_ROLES"
    ADD CONSTRAINT "PK_TAREAS_ROLES" PRIMARY KEY ("ID_TAREA", "ID_ROL");


--
-- Name: SGDP_TIPOS PK_TIPO; Type: CONSTRAINT; Schema: sgdp; Owner: sgdp
--

ALTER TABLE ONLY sgdp."SGDP_TIPOS"
    ADD CONSTRAINT "PK_TIPO" PRIMARY KEY ("ID_TIPO");


--
-- Name: SGDP_TIPOS_DE_DOCUMENTOS PK_TIPOS_DE_DOCUMENTOS; Type: CONSTRAINT; Schema: sgdp; Owner: sgdp
--

ALTER TABLE ONLY sgdp."SGDP_TIPOS_DE_DOCUMENTOS"
    ADD CONSTRAINT "PK_TIPOS_DE_DOCUMENTOS" PRIMARY KEY ("ID_TIPO_DE_DOCUMENTO");


--
-- Name: SGDP_TIPOS_DE_TAREAS_LIBRES PK_TIPOS_DE_TAREAS_LIBRES; Type: CONSTRAINT; Schema: sgdp; Owner: sgdp
--

ALTER TABLE ONLY sgdp."SGDP_TIPOS_DE_TAREAS_LIBRES"
    ADD CONSTRAINT "PK_TIPOS_DE_TAREAS_LIBRES" PRIMARY KEY ("ID_TIPO_DE_TAREA_LIBRE");


--
-- Name: SGDP_TIPO_PARAMETRO_DE_TAREA PK_TIPO_PARAMETRO_DE_TAREA; Type: CONSTRAINT; Schema: sgdp; Owner: sgdp
--

ALTER TABLE ONLY sgdp."SGDP_TIPO_PARAMETRO_DE_TAREA"
    ADD CONSTRAINT "PK_TIPO_PARAMETRO_DE_TAREA" PRIMARY KEY ("ID_TIPO_PARAMETRO_DE_TAREA");


--
-- Name: SGDP_USUARIOS_ASIGNADOS_A_TAREAS PK_USUARIOS_ASIGNADOS_A_TAREAS; Type: CONSTRAINT; Schema: sgdp; Owner: sgdp
--

ALTER TABLE ONLY sgdp."SGDP_USUARIOS_ASIGNADOS_A_TAREAS"
    ADD CONSTRAINT "PK_USUARIOS_ASIGNADOS_A_TAREAS" PRIMARY KEY ("ID_INSTANCIA_DE_TAREA", "ID_USUARIO");


--
-- Name: SGDP_USUARIOS_ROLES PK_USUARIOS_ROLES; Type: CONSTRAINT; Schema: sgdp; Owner: sgdp
--

ALTER TABLE ONLY sgdp."SGDP_USUARIOS_ROLES"
    ADD CONSTRAINT "PK_USUARIOS_ROLES" PRIMARY KEY ("ID_USUARIO_ROL");


--
-- Name: SGDP_VALOR_PARAMETRO_DE_TAREA PK_VALOR_PARAMETRO_DE_TAREA; Type: CONSTRAINT; Schema: sgdp; Owner: sgdp
--

ALTER TABLE ONLY sgdp."SGDP_VALOR_PARAMETRO_DE_TAREA"
    ADD CONSTRAINT "PK_VALOR_PARAMETRO_DE_TAREA" PRIMARY KEY ("ID_VALOR_PARAMETRO_DE_TAREA");


--
-- Name: SGDP_VINCULACION_EXP PK_VINCULACION_EXP; Type: CONSTRAINT; Schema: sgdp; Owner: sgdp
--

ALTER TABLE ONLY sgdp."SGDP_VINCULACION_EXP"
    ADD CONSTRAINT "PK_VINCULACION_EXP" PRIMARY KEY ("ID_VINCULACION_EXP");


--
-- Name: SGDP_ASIGNACIONES_NUMEROS_DOC SGDP_ASIGNACIONES_NUMEROS_DOC_pkey; Type: CONSTRAINT; Schema: sgdp; Owner: sgdp
--

ALTER TABLE ONLY sgdp."SGDP_ASIGNACIONES_NUMEROS_DOC"
    ADD CONSTRAINT "SGDP_ASIGNACIONES_NUMEROS_DOC_pkey" PRIMARY KEY ("ID_ASIGNACION_NUMERO_DOC");


--
-- Name: SGDP_HISTORICO_SEGUIMIENTO_INTANCIA_PROCESOS SGDP_HISTORIAL_SEGUIMIENTO_INTANCIA_PROCESOS_pkey1; Type: CONSTRAINT; Schema: sgdp; Owner: sgdp
--

ALTER TABLE ONLY sgdp."SGDP_HISTORICO_SEGUIMIENTO_INTANCIA_PROCESOS"
    ADD CONSTRAINT "SGDP_HISTORIAL_SEGUIMIENTO_INTANCIA_PROCESOS_pkey1" PRIMARY KEY ("ID_HISTORICO_INSTANCIA_PROCESO");


--
-- Name: SGDP_RESPONSABILIDAD_TAREA SGDP_RESPONSABILIDAD_TAREA_pkey; Type: CONSTRAINT; Schema: sgdp; Owner: sgdp
--

ALTER TABLE ONLY sgdp."SGDP_RESPONSABILIDAD_TAREA"
    ADD CONSTRAINT "SGDP_RESPONSABILIDAD_TAREA_pkey" PRIMARY KEY ("ID_RESPONSABILIDAD", "ID_TAREA");


--
-- Name: SGDP_RESPONSABILIDAD SGDP_RESPONSABILIDAD_pkey; Type: CONSTRAINT; Schema: sgdp; Owner: sgdp
--

ALTER TABLE ONLY sgdp."SGDP_RESPONSABILIDAD"
    ADD CONSTRAINT "SGDP_RESPONSABILIDAD_pkey" PRIMARY KEY ("ID_RESPONSABILIDAD");


--
-- Name: SGDP_SEGUIMIENTO_INTANCIA_PROCESOS SGDP_SEGUIMIENTO_INTANCIA_PROCESOS_pkey; Type: CONSTRAINT; Schema: sgdp; Owner: sgdp
--

ALTER TABLE ONLY sgdp."SGDP_SEGUIMIENTO_INTANCIA_PROCESOS"
    ADD CONSTRAINT "SGDP_SEGUIMIENTO_INTANCIA_PROCESOS_pkey" PRIMARY KEY ("ID_INSTANCIA_PROCESO", "ID_USUARIO");


--
-- Name: SGDP_UNIDADES SGDP_UNIDADES_pkey; Type: CONSTRAINT; Schema: sgdp; Owner: sgdp
--

ALTER TABLE ONLY sgdp."SGDP_UNIDADES"
    ADD CONSTRAINT "SGDP_UNIDADES_pkey" PRIMARY KEY ("ID_UNIDAD");


--
-- Name: SGDP_USUARIO_NOTIFICACION_TAREA SGDP_USUARIO_NOTIFICACION_TAREA_pkey; Type: CONSTRAINT; Schema: sgdp; Owner: sgdp
--

ALTER TABLE ONLY sgdp."SGDP_USUARIO_NOTIFICACION_TAREA"
    ADD CONSTRAINT "SGDP_USUARIO_NOTIFICACION_TAREA_pkey" PRIMARY KEY ("ID_USUARIO_NOTIFICACION_TAREA");


--
-- Name: SGDP_USUARIO_RESPONSABILIDAD SGDP_USUARIO_RESPONSABILIDAD_pkey; Type: CONSTRAINT; Schema: sgdp; Owner: sgdp
--

ALTER TABLE ONLY sgdp."SGDP_USUARIO_RESPONSABILIDAD"
    ADD CONSTRAINT "SGDP_USUARIO_RESPONSABILIDAD_pkey" PRIMARY KEY ("ID_USUARIO_RESPONSABILIDAD");


--
-- Name: SGDP_RESPONSABILIDAD UNQ01_SGDP_RESPONSABILIDAD; Type: CONSTRAINT; Schema: sgdp; Owner: sgdp
--

ALTER TABLE ONLY sgdp."SGDP_RESPONSABILIDAD"
    ADD CONSTRAINT "UNQ01_SGDP_RESPONSABILIDAD" UNIQUE ("ID_RESPONSABILIDAD");


--
-- Name: SGDP_RESPONSABILIDAD_TAREA UNQ01_SGDP_RESPONSABILIDAD_TAREA; Type: CONSTRAINT; Schema: sgdp; Owner: sgdp
--

ALTER TABLE ONLY sgdp."SGDP_RESPONSABILIDAD_TAREA"
    ADD CONSTRAINT "UNQ01_SGDP_RESPONSABILIDAD_TAREA" UNIQUE ("ID_RESPONSABILIDAD", "ID_TAREA");


--
-- Name: SGDP_USUARIOS_ROLES UNQ01_SGDP_USUARIOS_ROLES; Type: CONSTRAINT; Schema: sgdp; Owner: sgdp
--

ALTER TABLE ONLY sgdp."SGDP_USUARIOS_ROLES"
    ADD CONSTRAINT "UNQ01_SGDP_USUARIOS_ROLES" UNIQUE ("ID_ROL", "ID_USUARIO");


--
-- Name: SGDP_USUARIO_NOTIFICACION_TAREA UNQ01_SGDP_USUARIO_NOTIFICACION_TAREA; Type: CONSTRAINT; Schema: sgdp; Owner: sgdp
--

ALTER TABLE ONLY sgdp."SGDP_USUARIO_NOTIFICACION_TAREA"
    ADD CONSTRAINT "UNQ01_SGDP_USUARIO_NOTIFICACION_TAREA" UNIQUE ("ID_USUARIO", "ID_TAREA");


--
-- Name: SGDP_USUARIO_RESPONSABILIDAD UNQ01_SGDP_USUARIO_RESPONSABILIDAD; Type: CONSTRAINT; Schema: sgdp; Owner: sgdp
--

ALTER TABLE ONLY sgdp."SGDP_USUARIO_RESPONSABILIDAD"
    ADD CONSTRAINT "UNQ01_SGDP_USUARIO_RESPONSABILIDAD" UNIQUE ("ID_USUARIO", "ID_RESPONSABILIDAD");


--
-- Name: SGDP_VINCULACION_EXP UNQ01_VINCULACION_EXP; Type: CONSTRAINT; Schema: sgdp; Owner: sgdp
--

ALTER TABLE ONLY sgdp."SGDP_VINCULACION_EXP"
    ADD CONSTRAINT "UNQ01_VINCULACION_EXP" UNIQUE ("ID_INSTANCIA_DE_PROCESO", "ID_INSTANCIA_DE_PROCESO_ANTECESOR");


--
-- Name: SGDP_LOG_FUERA_DE_OFICINA UNQ_ID_LOG_FUERA_DE_OFICINA; Type: CONSTRAINT; Schema: sgdp; Owner: sgdp
--

ALTER TABLE ONLY sgdp."SGDP_LOG_FUERA_DE_OFICINA"
    ADD CONSTRAINT "UNQ_ID_LOG_FUERA_DE_OFICINA" UNIQUE ("ID_LOG_FUERA_DE_OFICINA");


--
-- Name: IDX_01_PERSPECTIVAS; Type: INDEX; Schema: sgdp; Owner: sgdp
--

CREATE INDEX "IDX_01_PERSPECTIVAS" ON sgdp."SGDP_PERSPECTIVAS" USING btree ("ID_PERSPECTIVA");


--
-- Name: IDX_ID_ARCHIVO_CMS; Type: INDEX; Schema: sgdp; Owner: sgdp
--

CREATE INDEX "IDX_ID_ARCHIVO_CMS" ON sgdp."SGDP_HISTORICO_ARCHIVOS_INST_DE_TAREAS" USING btree ("ID_ARCHIVO_CMS");


--
-- Name: IDX_ID_HISTORICO_DE_INST_DE_TAREA; Type: INDEX; Schema: sgdp; Owner: sgdp
--

CREATE INDEX "IDX_ID_HISTORICO_DE_INST_DE_TAREA" ON sgdp."SGDP_HISTORICO_ARCHIVOS_INST_DE_TAREAS" USING btree ("ID_HISTORICO_DE_INST_DE_TAREA");


--
-- Name: PK_HISTORICO_FIRMAS; Type: INDEX; Schema: sgdp; Owner: sgdp
--

CREATE UNIQUE INDEX "PK_HISTORICO_FIRMAS" ON sgdp."SGDP_HISTORICO_FIRMAS" USING btree ("ID_HISTORICO_FIRMA");


--
-- Name: SGDP_MACRO_PROCESOS_ID_MACRO_PROCESO_idx; Type: INDEX; Schema: sgdp; Owner: sgdp
--

CREATE INDEX "SGDP_MACRO_PROCESOS_ID_MACRO_PROCESO_idx" ON sgdp."SGDP_MACRO_PROCESOS" USING btree ("ID_MACRO_PROCESO");


--
-- Name: SGDP_PROCESOS_ID_PROCESO_idx; Type: INDEX; Schema: sgdp; Owner: sgdp
--

CREATE INDEX "SGDP_PROCESOS_ID_PROCESO_idx" ON sgdp."SGDP_PROCESOS" USING btree ("ID_PROCESO");


--
-- Name: SGDP_PROCESOS_ID_PROCESO_idx2; Type: INDEX; Schema: sgdp; Owner: sgdp
--

CREATE INDEX "SGDP_PROCESOS_ID_PROCESO_idx2" ON sgdp."SGDP_PROCESOS" USING btree ("ID_MACRO_PROCESO", "B_VIGENTE");


--
-- Name: SGDP_TAREAS_ID_TAREA_idx; Type: INDEX; Schema: sgdp; Owner: sgdp
--

CREATE INDEX "SGDP_TAREAS_ID_TAREA_idx" ON sgdp."SGDP_TAREAS" USING btree ("ID_TAREA");


--
-- Name: fki_FK01_HISTORICO_DE_INST_DE_TAREAS; Type: INDEX; Schema: sgdp; Owner: sgdp
--

CREATE INDEX "fki_FK01_HISTORICO_DE_INST_DE_TAREAS" ON sgdp."SGDP_HISTORICO_DE_INST_DE_TAREAS" USING btree ("ID_INSTANCIA_DE_TAREA_DE_ORIGEN");


--
-- Name: fki_FK01_INSTANCIAS_DE_TAREAS; Type: INDEX; Schema: sgdp; Owner: sgdp
--

CREATE INDEX "fki_FK01_INSTANCIAS_DE_TAREAS" ON sgdp."SGDP_INSTANCIAS_DE_TAREAS" USING btree ("ID_TAREA");


--
-- Name: fki_FK01_INSTANCIAS_DE_TAREAS_LIBRES; Type: INDEX; Schema: sgdp; Owner: sgdp
--

CREATE INDEX "fki_FK01_INSTANCIAS_DE_TAREAS_LIBRES" ON sgdp."SGDP_INSTANCIAS_DE_TAREAS_LIBRES" USING btree ("ID_INSTANCIA_DE_TAREA_LIBRE_PADRE");


--
-- Name: fki_FK01_INSTANCIAS_PROCESOS; Type: INDEX; Schema: sgdp; Owner: sgdp
--

CREATE INDEX "fki_FK01_INSTANCIAS_PROCESOS" ON sgdp."SGDP_INSTANCIAS_DE_PROCESOS" USING btree ("ID_PROCESO");


--
-- Name: fki_FK01_MACRO_PROCESOS; Type: INDEX; Schema: sgdp; Owner: sgdp
--

CREATE INDEX "fki_FK01_MACRO_PROCESOS" ON sgdp."SGDP_MACRO_PROCESOS" USING btree ("ID_PERSPECTIVA");


--
-- Name: fki_FK01_PARAMETRO_RELACION_TAREA; Type: INDEX; Schema: sgdp; Owner: sgdp
--

CREATE INDEX "fki_FK01_PARAMETRO_RELACION_TAREA" ON sgdp."SGDP_PARAMETRO_RELACION_TAREA" USING btree ("ID_TAREA");


--
-- Name: fki_FK01_PROCESOS; Type: INDEX; Schema: sgdp; Owner: sgdp
--

CREATE INDEX "fki_FK01_PROCESOS" ON sgdp."SGDP_PROCESOS" USING btree ("ID_MACRO_PROCESO");


--
-- Name: fki_FK01_SOLICITUD_CREACION_EXP; Type: INDEX; Schema: sgdp; Owner: sgdp
--

CREATE INDEX "fki_FK01_SOLICITUD_CREACION_EXP" ON sgdp."SGDP_SOLICITUD_CREACION_EXP" USING btree ("ID_INSTANCIA_DE_PROCESO");


--
-- Name: fki_FK01_TAREAS; Type: INDEX; Schema: sgdp; Owner: sgdp
--

CREATE INDEX "fki_FK01_TAREAS" ON sgdp."SGDP_TAREAS" USING btree ("ID_PROCESO");


--
-- Name: fki_FK01_USUARIOS_ROLES; Type: INDEX; Schema: sgdp; Owner: sgdp
--

CREATE INDEX "fki_FK01_USUARIOS_ROLES" ON sgdp."SGDP_USUARIOS_ROLES" USING btree ("ID_ROL");


--
-- Name: fki_FK02_DOCUMENTOS_DE_SALIDA_DE_TAREAS; Type: INDEX; Schema: sgdp; Owner: sgdp
--

CREATE INDEX "fki_FK02_DOCUMENTOS_DE_SALIDA_DE_TAREAS" ON sgdp."SGDP_DOCUMENTOS_DE_SALIDA_DE_TAREAS" USING btree ("ID_TIPO_DE_DOCUMENTO");


--
-- Name: fki_FK02_HISTORICO_DE_INST_DE_TAREAS; Type: INDEX; Schema: sgdp; Owner: sgdp
--

CREATE INDEX "fki_FK02_HISTORICO_DE_INST_DE_TAREAS" ON sgdp."SGDP_HISTORICO_DE_INST_DE_TAREAS" USING btree ("ID_INSTANCIA_DE_TAREA_DESTINO");


--
-- Name: fki_FK02_INSTANCIAS_DE_PROCESOS; Type: INDEX; Schema: sgdp; Owner: sgdp
--

CREATE INDEX "fki_FK02_INSTANCIAS_DE_PROCESOS" ON sgdp."SGDP_INSTANCIAS_DE_PROCESOS" USING btree ("ID_ESTADO_DE_PROCESO");


--
-- Name: fki_FK02_INSTANCIAS_DE_TAREAS; Type: INDEX; Schema: sgdp; Owner: sgdp
--

CREATE INDEX "fki_FK02_INSTANCIAS_DE_TAREAS" ON sgdp."SGDP_INSTANCIAS_DE_TAREAS" USING btree ("ID_INSTANCIA_DE_PROCESO");


--
-- Name: fki_FK02_INSTANCIAS_DE_TAREAS_LIBRES; Type: INDEX; Schema: sgdp; Owner: sgdp
--

CREATE INDEX "fki_FK02_INSTANCIAS_DE_TAREAS_LIBRES" ON sgdp."SGDP_INSTANCIAS_DE_TAREAS_LIBRES" USING btree ("ID_ESTADO_DE_TAREA");


--
-- Name: fki_FK02_PARAMETRO_RELACION_TAREA; Type: INDEX; Schema: sgdp; Owner: sgdp
--

CREATE INDEX "fki_FK02_PARAMETRO_RELACION_TAREA" ON sgdp."SGDP_PARAMETRO_RELACION_TAREA" USING btree ("ID_PARAM_TAREA");


--
-- Name: fki_FK02_PROCESOS; Type: INDEX; Schema: sgdp; Owner: sgdp
--

CREATE INDEX "fki_FK02_PROCESOS" ON sgdp."SGDP_PROCESOS" USING btree ("ID_UNIDAD");


--
-- Name: fki_FK02_SOLICITUD_CREACION_EXP; Type: INDEX; Schema: sgdp; Owner: sgdp
--

CREATE INDEX "fki_FK02_SOLICITUD_CREACION_EXP" ON sgdp."SGDP_SOLICITUD_CREACION_EXP" USING btree ("ID_ESTADO_SOLICITUD_CREACION_EXP");


--
-- Name: fki_FK02_TAREAS_ROLES; Type: INDEX; Schema: sgdp; Owner: sgdp
--

CREATE INDEX "fki_FK02_TAREAS_ROLES" ON sgdp."SGDP_TAREAS_ROLES" USING btree ("ID_ROL");


--
-- Name: fki_FK02_USUARIOS_ROLES; Type: INDEX; Schema: sgdp; Owner: sgdp
--

CREATE INDEX "fki_FK02_USUARIOS_ROLES" ON sgdp."SGDP_USUARIOS_ROLES" USING btree ("ID_UNIDAD");


--
-- Name: fki_FK03_HISTORICO_DE_INST_DE_TAREAS; Type: INDEX; Schema: sgdp; Owner: sgdp
--

CREATE INDEX "fki_FK03_HISTORICO_DE_INST_DE_TAREAS" ON sgdp."SGDP_HISTORICO_DE_INST_DE_TAREAS" USING btree ("ID_ACCION_HISTORICO_INST_DE_TAREA");


--
-- Name: fki_FK03_INSTANCIAS_DE_TAREAS; Type: INDEX; Schema: sgdp; Owner: sgdp
--

CREATE INDEX "fki_FK03_INSTANCIAS_DE_TAREAS" ON sgdp."SGDP_INSTANCIAS_DE_TAREAS" USING btree ("ID_ESTADO_DE_TAREA");


--
-- Name: fki_FK03_INSTANCIAS_DE_TAREAS_LIBRES; Type: INDEX; Schema: sgdp; Owner: sgdp
--

CREATE INDEX "fki_FK03_INSTANCIAS_DE_TAREAS_LIBRES" ON sgdp."SGDP_INSTANCIAS_DE_TAREAS_LIBRES" USING btree ("ID_TIPO_DE_TAREA_LIBRE");


--
-- Name: fki_FK03_SOLICITUD_CREACION_EXP; Type: INDEX; Schema: sgdp; Owner: sgdp
--

CREATE INDEX "fki_FK03_SOLICITUD_CREACION_EXP" ON sgdp."SGDP_SOLICITUD_CREACION_EXP" USING btree ("ID_PROCESO");


--
-- Name: fki_FK03_TAREAS; Type: INDEX; Schema: sgdp; Owner: sgdp
--

CREATE INDEX "fki_FK03_TAREAS" ON sgdp."SGDP_TAREAS" USING btree ("ID_ETAPA");


--
-- Name: SGDP_ARCHIVOS_INST_DE_TAREA FK01_ARCHIVOS_INST_DE_TAREA; Type: FK CONSTRAINT; Schema: sgdp; Owner: sgdp
--

ALTER TABLE ONLY sgdp."SGDP_ARCHIVOS_INST_DE_TAREA"
    ADD CONSTRAINT "FK01_ARCHIVOS_INST_DE_TAREA" FOREIGN KEY ("ID_INSTANCIA_DE_TAREA") REFERENCES sgdp."SGDP_INSTANCIAS_DE_TAREAS"("ID_INSTANCIA_DE_TAREA");


--
-- Name: SGDP_ASIGNACIONES_NUMEROS_DOC FK01_ASIGNACION_NUMERO_DOC; Type: FK CONSTRAINT; Schema: sgdp; Owner: sgdp
--

ALTER TABLE ONLY sgdp."SGDP_ASIGNACIONES_NUMEROS_DOC"
    ADD CONSTRAINT "FK01_ASIGNACION_NUMERO_DOC" FOREIGN KEY ("ID_TIPO_DE_DOCUMENTO") REFERENCES sgdp."SGDP_TIPOS_DE_DOCUMENTOS"("ID_TIPO_DE_DOCUMENTO");


--
-- Name: SGDP_DETALLES_CARGA FK01_CARGAS; Type: FK CONSTRAINT; Schema: sgdp; Owner: sgdp
--

ALTER TABLE ONLY sgdp."SGDP_DETALLES_CARGA"
    ADD CONSTRAINT "FK01_CARGAS" FOREIGN KEY ("ID_CARGA") REFERENCES sgdp."SGDP_CARGAS"("ID_CARGA");


--
-- Name: SGDP_LOG_CARGA FK01_CARGAS; Type: FK CONSTRAINT; Schema: sgdp; Owner: sgdp
--

ALTER TABLE ONLY sgdp."SGDP_LOG_CARGA"
    ADD CONSTRAINT "FK01_CARGAS" FOREIGN KEY ("ID_CARGA") REFERENCES sgdp."SGDP_CARGAS"("ID_CARGA");


--
-- Name: SGDP_CARGO_RESPONSABILIDAD FK01_CARGO_RESPONSABILIDAD; Type: FK CONSTRAINT; Schema: sgdp; Owner: sgdp
--

ALTER TABLE ONLY sgdp."SGDP_CARGO_RESPONSABILIDAD"
    ADD CONSTRAINT "FK01_CARGO_RESPONSABILIDAD" FOREIGN KEY ("ID_CARGO") REFERENCES sgdp."SGDP_CARGO"("ID_CARGO");


--
-- Name: SGDP_DOCUMENTOS_DE_SALIDA_DE_TAREAS FK01_DOCUMENTOS_DE_SALIDA_DE_TAREAS; Type: FK CONSTRAINT; Schema: sgdp; Owner: sgdp
--

ALTER TABLE ONLY sgdp."SGDP_DOCUMENTOS_DE_SALIDA_DE_TAREAS"
    ADD CONSTRAINT "FK01_DOCUMENTOS_DE_SALIDA_DE_TAREAS" FOREIGN KEY ("ID_TAREA") REFERENCES sgdp."SGDP_TAREAS"("ID_TAREA");


--
-- Name: SGDP_HISTORICO_ARCHIVOS_INST_DE_TAREAS FK01_HISTORICO_ARCHIVOS_INST_DE_TAREAS; Type: FK CONSTRAINT; Schema: sgdp; Owner: sgdp
--

ALTER TABLE ONLY sgdp."SGDP_HISTORICO_ARCHIVOS_INST_DE_TAREAS"
    ADD CONSTRAINT "FK01_HISTORICO_ARCHIVOS_INST_DE_TAREAS" FOREIGN KEY ("ID_HISTORICO_DE_INST_DE_TAREA") REFERENCES sgdp."SGDP_HISTORICO_DE_INST_DE_TAREAS"("ID_HISTORICO_DE_INST_DE_TAREA");


--
-- Name: SGDP_HISTORICO_DE_INST_DE_TAREAS FK01_HISTORICO_DE_INST_DE_TAREAS; Type: FK CONSTRAINT; Schema: sgdp; Owner: sgdp
--

ALTER TABLE ONLY sgdp."SGDP_HISTORICO_DE_INST_DE_TAREAS"
    ADD CONSTRAINT "FK01_HISTORICO_DE_INST_DE_TAREAS" FOREIGN KEY ("ID_INSTANCIA_DE_TAREA_DE_ORIGEN") REFERENCES sgdp."SGDP_INSTANCIAS_DE_TAREAS"("ID_INSTANCIA_DE_TAREA");


--
-- Name: SGDP_HISTORICO_FIRMAS FK01_HISTORICO_FIRMAS; Type: FK CONSTRAINT; Schema: sgdp; Owner: sgdp
--

ALTER TABLE ONLY sgdp."SGDP_HISTORICO_FIRMAS"
    ADD CONSTRAINT "FK01_HISTORICO_FIRMAS" FOREIGN KEY ("ID_INSTANCIA_DE_TAREA") REFERENCES sgdp."SGDP_INSTANCIAS_DE_TAREAS"("ID_INSTANCIA_DE_TAREA");


--
-- Name: SGDP_HISTORICO_SOLICITUD_CREACION_EXP FK01_HISTORICO_SOLICITUD_CREACION_EXP; Type: FK CONSTRAINT; Schema: sgdp; Owner: sgdp
--

ALTER TABLE ONLY sgdp."SGDP_HISTORICO_SOLICITUD_CREACION_EXP"
    ADD CONSTRAINT "FK01_HISTORICO_SOLICITUD_CREACION_EXP" FOREIGN KEY ("ID_SOLICITUD_CREACION_EXP") REFERENCES sgdp."SGDP_SOLICITUD_CREACION_EXP"("ID_SOLICITUD_CREACION_EXP");


--
-- Name: SGDP_HISTORICO_USUARIOS_ASIGNADOS_A_TAREAS FK01_HISTORICO_USUARIOS_ASIGNADOS_A_TAREAS; Type: FK CONSTRAINT; Schema: sgdp; Owner: sgdp
--

ALTER TABLE ONLY sgdp."SGDP_HISTORICO_USUARIOS_ASIGNADOS_A_TAREAS"
    ADD CONSTRAINT "FK01_HISTORICO_USUARIOS_ASIGNADOS_A_TAREAS" FOREIGN KEY ("ID_HISTORICO_DE_INST_DE_TAREA") REFERENCES sgdp."SGDP_HISTORICO_DE_INST_DE_TAREAS"("ID_HISTORICO_DE_INST_DE_TAREA");


--
-- Name: SGDP_HISTORICO_VALOR_PARAMETRO_DE_TAREA FK01_HISTORICO_VALOR_PARAMETRO_DE_TAREA; Type: FK CONSTRAINT; Schema: sgdp; Owner: sgdp
--

ALTER TABLE ONLY sgdp."SGDP_HISTORICO_VALOR_PARAMETRO_DE_TAREA"
    ADD CONSTRAINT "FK01_HISTORICO_VALOR_PARAMETRO_DE_TAREA" FOREIGN KEY ("ID_PARAM_TAREA") REFERENCES sgdp."SGDP_PARAMETRO_DE_TAREA"("ID_PARAM_TAREA");


--
-- Name: SGDP_HISTORICO_VINCULACION_EXP FK01_HISTORICO_VINCULACION_EXP; Type: FK CONSTRAINT; Schema: sgdp; Owner: sgdp
--

ALTER TABLE ONLY sgdp."SGDP_HISTORICO_VINCULACION_EXP"
    ADD CONSTRAINT "FK01_HISTORICO_VINCULACION_EXP" FOREIGN KEY ("ID_INSTANCIA_DE_PROCESO") REFERENCES sgdp."SGDP_INSTANCIAS_DE_PROCESOS"("ID_INSTANCIA_DE_PROCESO");


--
-- Name: SGDP_TIPOS_DE_DOCUMENTOS FK01_ID_CATEGORIA_DE_TIPO_DE_DOCUMENTO; Type: FK CONSTRAINT; Schema: sgdp; Owner: sgdp
--

ALTER TABLE ONLY sgdp."SGDP_TIPOS_DE_DOCUMENTOS"
    ADD CONSTRAINT "FK01_ID_CATEGORIA_DE_TIPO_DE_DOCUMENTO" FOREIGN KEY ("ID_CATEGORIA_DE_TIPO_DE_DOCUMENTO") REFERENCES sgdp."SGDP_CATEGORIA_DE_TIPO_DE_DOCUMENTO"("ID_CATEGORIA_DE_TIPO_DE_DOCUMENTO");


--
-- Name: SGDP_INSTANCIAS_DE_PROCESOS FK01_INSTANCIAS_DE_PROCESOS; Type: FK CONSTRAINT; Schema: sgdp; Owner: sgdp
--

ALTER TABLE ONLY sgdp."SGDP_INSTANCIAS_DE_PROCESOS"
    ADD CONSTRAINT "FK01_INSTANCIAS_DE_PROCESOS" FOREIGN KEY ("ID_PROCESO") REFERENCES sgdp."SGDP_PROCESOS"("ID_PROCESO");


--
-- Name: SGDP_INSTANCIAS_DE_TAREAS FK01_INSTANCIAS_DE_TAREAS; Type: FK CONSTRAINT; Schema: sgdp; Owner: sgdp
--

ALTER TABLE ONLY sgdp."SGDP_INSTANCIAS_DE_TAREAS"
    ADD CONSTRAINT "FK01_INSTANCIAS_DE_TAREAS" FOREIGN KEY ("ID_TAREA") REFERENCES sgdp."SGDP_TAREAS"("ID_TAREA");


--
-- Name: SGDP_INSTANCIAS_DE_TAREAS_LIBRES FK01_INSTANCIAS_DE_TAREAS_LIBRES; Type: FK CONSTRAINT; Schema: sgdp; Owner: sgdp
--

ALTER TABLE ONLY sgdp."SGDP_INSTANCIAS_DE_TAREAS_LIBRES"
    ADD CONSTRAINT "FK01_INSTANCIAS_DE_TAREAS_LIBRES" FOREIGN KEY ("ID_INSTANCIA_DE_TAREA_LIBRE_PADRE") REFERENCES sgdp."SGDP_INSTANCIAS_DE_TAREAS_LIBRES"("ID_INSTANCIA_DE_TAREA_LIBRE");


--
-- Name: SGDP_HISTORICO_FECHA_VENC_INS_PROC FK01_INSTANCIA_DE_TAREA; Type: FK CONSTRAINT; Schema: sgdp; Owner: sgdp
--

ALTER TABLE ONLY sgdp."SGDP_HISTORICO_FECHA_VENC_INS_PROC"
    ADD CONSTRAINT "FK01_INSTANCIA_DE_TAREA" FOREIGN KEY ("ID_INSTANCIA_DE_TAREA") REFERENCES sgdp."SGDP_INSTANCIAS_DE_TAREAS"("ID_INSTANCIA_DE_TAREA");


--
-- Name: SGDP_MACRO_PROCESOS FK01_MACRO_PROCESOS; Type: FK CONSTRAINT; Schema: sgdp; Owner: sgdp
--

ALTER TABLE ONLY sgdp."SGDP_MACRO_PROCESOS"
    ADD CONSTRAINT "FK01_MACRO_PROCESOS" FOREIGN KEY ("ID_PERSPECTIVA") REFERENCES sgdp."SGDP_PERSPECTIVAS"("ID_PERSPECTIVA");


--
-- Name: SGDP_PARAMETRO_DE_TAREA FK01_PARAMETRO_DE_TAREA; Type: FK CONSTRAINT; Schema: sgdp; Owner: sgdp
--

ALTER TABLE ONLY sgdp."SGDP_PARAMETRO_DE_TAREA"
    ADD CONSTRAINT "FK01_PARAMETRO_DE_TAREA" FOREIGN KEY ("ID_TIPO_PARAMETRO_DE_TAREA") REFERENCES sgdp."SGDP_TIPO_PARAMETRO_DE_TAREA"("ID_TIPO_PARAMETRO_DE_TAREA");


--
-- Name: SGDP_PARAMETRO_RELACION_TAREA FK01_PARAMETRO_RELACION_TAREA; Type: FK CONSTRAINT; Schema: sgdp; Owner: sgdp
--

ALTER TABLE ONLY sgdp."SGDP_PARAMETRO_RELACION_TAREA"
    ADD CONSTRAINT "FK01_PARAMETRO_RELACION_TAREA" FOREIGN KEY ("ID_TAREA") REFERENCES sgdp."SGDP_TAREAS"("ID_TAREA");


--
-- Name: SGDP_PERMISOS FK01_PERMISOS; Type: FK CONSTRAINT; Schema: sgdp; Owner: sgdp
--

ALTER TABLE ONLY sgdp."SGDP_PERMISOS"
    ADD CONSTRAINT "FK01_PERMISOS" FOREIGN KEY ("ID_ROL") REFERENCES sgdp."SGDP_ROLES"("ID_ROL");


--
-- Name: SGDP_PROCESOS FK01_PROCESOS; Type: FK CONSTRAINT; Schema: sgdp; Owner: sgdp
--

ALTER TABLE ONLY sgdp."SGDP_PROCESOS"
    ADD CONSTRAINT "FK01_PROCESOS" FOREIGN KEY ("ID_MACRO_PROCESO") REFERENCES sgdp."SGDP_MACRO_PROCESOS"("ID_MACRO_PROCESO");


--
-- Name: SGDP_REFERENCIAS_DE_TAREAS FK01_REFERENCIAS_DE_TAREAS; Type: FK CONSTRAINT; Schema: sgdp; Owner: sgdp
--

ALTER TABLE ONLY sgdp."SGDP_REFERENCIAS_DE_TAREAS"
    ADD CONSTRAINT "FK01_REFERENCIAS_DE_TAREAS" FOREIGN KEY ("ID_TAREA") REFERENCES sgdp."SGDP_TAREAS"("ID_TAREA");


--
-- Name: SGDP_RESPONSABILIDAD_TAREA FK01_RESPONSABILIDAD_TAREA; Type: FK CONSTRAINT; Schema: sgdp; Owner: sgdp
--

ALTER TABLE ONLY sgdp."SGDP_RESPONSABILIDAD_TAREA"
    ADD CONSTRAINT "FK01_RESPONSABILIDAD_TAREA" FOREIGN KEY ("ID_TAREA") REFERENCES sgdp."SGDP_TAREAS"("ID_TAREA");


--
-- Name: SGDP_SOLICITUD_CREACION_EXP FK01_SOLICITUD_CREACION_EXP; Type: FK CONSTRAINT; Schema: sgdp; Owner: sgdp
--

ALTER TABLE ONLY sgdp."SGDP_SOLICITUD_CREACION_EXP"
    ADD CONSTRAINT "FK01_SOLICITUD_CREACION_EXP" FOREIGN KEY ("ID_INSTANCIA_DE_PROCESO") REFERENCES sgdp."SGDP_INSTANCIAS_DE_PROCESOS"("ID_INSTANCIA_DE_PROCESO");


--
-- Name: SGDP_TAREAS FK01_TAREAS; Type: FK CONSTRAINT; Schema: sgdp; Owner: sgdp
--

ALTER TABLE ONLY sgdp."SGDP_TAREAS"
    ADD CONSTRAINT "FK01_TAREAS" FOREIGN KEY ("ID_PROCESO") REFERENCES sgdp."SGDP_PROCESOS"("ID_PROCESO");


--
-- Name: SGDP_TAREAS_INICIA_PROCESOS FK01_TAREAS_INICIA_PROCESOS; Type: FK CONSTRAINT; Schema: sgdp; Owner: sgdp
--

ALTER TABLE ONLY sgdp."SGDP_TAREAS_INICIA_PROCESOS"
    ADD CONSTRAINT "FK01_TAREAS_INICIA_PROCESOS" FOREIGN KEY ("ID_TAREA") REFERENCES sgdp."SGDP_TAREAS"("ID_TAREA");


--
-- Name: SGDP_TAREAS_ROLES FK01_TAREAS_ROLES; Type: FK CONSTRAINT; Schema: sgdp; Owner: sgdp
--

ALTER TABLE ONLY sgdp."SGDP_TAREAS_ROLES"
    ADD CONSTRAINT "FK01_TAREAS_ROLES" FOREIGN KEY ("ID_TAREA") REFERENCES sgdp."SGDP_TAREAS"("ID_TAREA");


--
-- Name: SGDP_ARCHIVOS_INST_DE_TAREA_METADATA FK01_TIPOS; Type: FK CONSTRAINT; Schema: sgdp; Owner: sgdp
--

ALTER TABLE ONLY sgdp."SGDP_ARCHIVOS_INST_DE_TAREA_METADATA"
    ADD CONSTRAINT "FK01_TIPOS" FOREIGN KEY ("ID_TIPO") REFERENCES sgdp."SGDP_TIPOS"("ID_TIPO");


--
-- Name: SGDP_USUARIOS_ASIGNADOS_A_TAREAS FK01_USUARIOS_ASIGNADOS; Type: FK CONSTRAINT; Schema: sgdp; Owner: sgdp
--

ALTER TABLE ONLY sgdp."SGDP_USUARIOS_ASIGNADOS_A_TAREAS"
    ADD CONSTRAINT "FK01_USUARIOS_ASIGNADOS" FOREIGN KEY ("ID_INSTANCIA_DE_TAREA") REFERENCES sgdp."SGDP_INSTANCIAS_DE_TAREAS"("ID_INSTANCIA_DE_TAREA");


--
-- Name: SGDP_USUARIOS_ROLES FK01_USUARIOS_ROLES; Type: FK CONSTRAINT; Schema: sgdp; Owner: sgdp
--

ALTER TABLE ONLY sgdp."SGDP_USUARIOS_ROLES"
    ADD CONSTRAINT "FK01_USUARIOS_ROLES" FOREIGN KEY ("ID_ROL") REFERENCES sgdp."SGDP_ROLES"("ID_ROL");


--
-- Name: SGDP_USUARIO_NOTIFICACION_TAREA FK01_USUARIO_NOTIFICACION_TAREA; Type: FK CONSTRAINT; Schema: sgdp; Owner: sgdp
--

ALTER TABLE ONLY sgdp."SGDP_USUARIO_NOTIFICACION_TAREA"
    ADD CONSTRAINT "FK01_USUARIO_NOTIFICACION_TAREA" FOREIGN KEY ("ID_TAREA") REFERENCES sgdp."SGDP_TAREAS"("ID_TAREA");


--
-- Name: SGDP_USUARIO_RESPONSABILIDAD FK01_USUARIO_RESPONSABILIDAD; Type: FK CONSTRAINT; Schema: sgdp; Owner: sgdp
--

ALTER TABLE ONLY sgdp."SGDP_USUARIO_RESPONSABILIDAD"
    ADD CONSTRAINT "FK01_USUARIO_RESPONSABILIDAD" FOREIGN KEY ("ID_RESPONSABILIDAD") REFERENCES sgdp."SGDP_RESPONSABILIDAD"("ID_RESPONSABILIDAD");


--
-- Name: SGDP_VALOR_PARAMETRO_DE_TAREA FK01_VALOR_PARAMETRO_DE_TAREA; Type: FK CONSTRAINT; Schema: sgdp; Owner: sgdp
--

ALTER TABLE ONLY sgdp."SGDP_VALOR_PARAMETRO_DE_TAREA"
    ADD CONSTRAINT "FK01_VALOR_PARAMETRO_DE_TAREA" FOREIGN KEY ("ID_PARAM_TAREA") REFERENCES sgdp."SGDP_PARAMETRO_DE_TAREA"("ID_PARAM_TAREA");


--
-- Name: SGDP_VINCULACION_EXP FK01_VINCULACION_EXP; Type: FK CONSTRAINT; Schema: sgdp; Owner: sgdp
--

ALTER TABLE ONLY sgdp."SGDP_VINCULACION_EXP"
    ADD CONSTRAINT "FK01_VINCULACION_EXP" FOREIGN KEY ("ID_INSTANCIA_DE_PROCESO") REFERENCES sgdp."SGDP_INSTANCIAS_DE_PROCESOS"("ID_INSTANCIA_DE_PROCESO");


--
-- Name: SGDP_ARCHIVOS_INST_DE_TAREA FK02_ARCHIVOS_INST_DE_TAREA; Type: FK CONSTRAINT; Schema: sgdp; Owner: sgdp
--

ALTER TABLE ONLY sgdp."SGDP_ARCHIVOS_INST_DE_TAREA"
    ADD CONSTRAINT "FK02_ARCHIVOS_INST_DE_TAREA" FOREIGN KEY ("ID_TIPO_DE_DOCUMENTO") REFERENCES sgdp."SGDP_TIPOS_DE_DOCUMENTOS"("ID_TIPO_DE_DOCUMENTO");


--
-- Name: SGDP_CARGO_RESPONSABILIDAD FK02_CARGO_RESPONSABILIDAD; Type: FK CONSTRAINT; Schema: sgdp; Owner: sgdp
--

ALTER TABLE ONLY sgdp."SGDP_CARGO_RESPONSABILIDAD"
    ADD CONSTRAINT "FK02_CARGO_RESPONSABILIDAD" FOREIGN KEY ("ID_RESPONSABILIDAD") REFERENCES sgdp."SGDP_RESPONSABILIDAD"("ID_RESPONSABILIDAD");


--
-- Name: SGDP_DOCUMENTOS_DE_SALIDA_DE_TAREAS FK02_DOCUMENTOS_DE_SALIDA_DE_TAREAS; Type: FK CONSTRAINT; Schema: sgdp; Owner: sgdp
--

ALTER TABLE ONLY sgdp."SGDP_DOCUMENTOS_DE_SALIDA_DE_TAREAS"
    ADD CONSTRAINT "FK02_DOCUMENTOS_DE_SALIDA_DE_TAREAS" FOREIGN KEY ("ID_TIPO_DE_DOCUMENTO") REFERENCES sgdp."SGDP_TIPOS_DE_DOCUMENTOS"("ID_TIPO_DE_DOCUMENTO");


--
-- Name: SGDP_HISTORICO_ARCHIVOS_INST_DE_TAREAS FK02_HISTORICO_ARCHIVOS_INST_DE_TAREAS; Type: FK CONSTRAINT; Schema: sgdp; Owner: sgdp
--

ALTER TABLE ONLY sgdp."SGDP_HISTORICO_ARCHIVOS_INST_DE_TAREAS"
    ADD CONSTRAINT "FK02_HISTORICO_ARCHIVOS_INST_DE_TAREAS" FOREIGN KEY ("ID_TIPO_DE_DOCUMENTO") REFERENCES sgdp."SGDP_TIPOS_DE_DOCUMENTOS"("ID_TIPO_DE_DOCUMENTO");


--
-- Name: SGDP_HISTORICO_DE_INST_DE_TAREAS FK02_HISTORICO_DE_INST_DE_TAREAS; Type: FK CONSTRAINT; Schema: sgdp; Owner: sgdp
--

ALTER TABLE ONLY sgdp."SGDP_HISTORICO_DE_INST_DE_TAREAS"
    ADD CONSTRAINT "FK02_HISTORICO_DE_INST_DE_TAREAS" FOREIGN KEY ("ID_INSTANCIA_DE_TAREA_DESTINO") REFERENCES sgdp."SGDP_INSTANCIAS_DE_TAREAS"("ID_INSTANCIA_DE_TAREA");


--
-- Name: SGDP_HISTORICO_FIRMAS FK02_HISTORICO_FIRMAS; Type: FK CONSTRAINT; Schema: sgdp; Owner: sgdp
--

ALTER TABLE ONLY sgdp."SGDP_HISTORICO_FIRMAS"
    ADD CONSTRAINT "FK02_HISTORICO_FIRMAS" FOREIGN KEY ("ID_TIPO_DE_DOCUMENTO") REFERENCES sgdp."SGDP_TIPOS_DE_DOCUMENTOS"("ID_TIPO_DE_DOCUMENTO");


--
-- Name: SGDP_HISTORICO_SOLICITUD_CREACION_EXP FK02_HISTORICO_SOLICITUD_CREACION_EXP; Type: FK CONSTRAINT; Schema: sgdp; Owner: sgdp
--

ALTER TABLE ONLY sgdp."SGDP_HISTORICO_SOLICITUD_CREACION_EXP"
    ADD CONSTRAINT "FK02_HISTORICO_SOLICITUD_CREACION_EXP" FOREIGN KEY ("ID_INSTANCIA_DE_PROCESO") REFERENCES sgdp."SGDP_INSTANCIAS_DE_PROCESOS"("ID_INSTANCIA_DE_PROCESO");


--
-- Name: SGDP_HISTORICO_VALOR_PARAMETRO_DE_TAREA FK02_HISTORICO_VALOR_PARAMETRO_DE_TAREA; Type: FK CONSTRAINT; Schema: sgdp; Owner: sgdp
--

ALTER TABLE ONLY sgdp."SGDP_HISTORICO_VALOR_PARAMETRO_DE_TAREA"
    ADD CONSTRAINT "FK02_HISTORICO_VALOR_PARAMETRO_DE_TAREA" FOREIGN KEY ("ID_HISTORICO_DE_INST_DE_TAREA") REFERENCES sgdp."SGDP_HISTORICO_DE_INST_DE_TAREAS"("ID_HISTORICO_DE_INST_DE_TAREA");


--
-- Name: SGDP_HISTORICO_VINCULACION_EXP FK02_HISTORICO_VINCULACION_EXP; Type: FK CONSTRAINT; Schema: sgdp; Owner: sgdp
--

ALTER TABLE ONLY sgdp."SGDP_HISTORICO_VINCULACION_EXP"
    ADD CONSTRAINT "FK02_HISTORICO_VINCULACION_EXP" FOREIGN KEY ("ID_INSTANCIA_DE_PROCESO_ANTECESOR") REFERENCES sgdp."SGDP_INSTANCIAS_DE_PROCESOS"("ID_INSTANCIA_DE_PROCESO");


--
-- Name: SGDP_INSTANCIAS_DE_PROCESOS FK02_INSTANCIAS_DE_PROCESOS; Type: FK CONSTRAINT; Schema: sgdp; Owner: sgdp
--

ALTER TABLE ONLY sgdp."SGDP_INSTANCIAS_DE_PROCESOS"
    ADD CONSTRAINT "FK02_INSTANCIAS_DE_PROCESOS" FOREIGN KEY ("ID_ESTADO_DE_PROCESO") REFERENCES sgdp."SGDP_ESTADOS_DE_PROCESOS"("ID_ESTADO_DE_PROCESO");


--
-- Name: SGDP_INSTANCIAS_DE_TAREAS FK02_INSTANCIAS_DE_TAREAS; Type: FK CONSTRAINT; Schema: sgdp; Owner: sgdp
--

ALTER TABLE ONLY sgdp."SGDP_INSTANCIAS_DE_TAREAS"
    ADD CONSTRAINT "FK02_INSTANCIAS_DE_TAREAS" FOREIGN KEY ("ID_INSTANCIA_DE_PROCESO") REFERENCES sgdp."SGDP_INSTANCIAS_DE_PROCESOS"("ID_INSTANCIA_DE_PROCESO");


--
-- Name: SGDP_INSTANCIAS_DE_TAREAS_LIBRES FK02_INSTANCIAS_DE_TAREAS_LIBRES; Type: FK CONSTRAINT; Schema: sgdp; Owner: sgdp
--

ALTER TABLE ONLY sgdp."SGDP_INSTANCIAS_DE_TAREAS_LIBRES"
    ADD CONSTRAINT "FK02_INSTANCIAS_DE_TAREAS_LIBRES" FOREIGN KEY ("ID_ESTADO_DE_TAREA") REFERENCES sgdp."SGDP_ESTADOS_DE_TAREAS"("ID_ESTADO_DE_TAREA");


--
-- Name: SGDP_PARAMETRO_RELACION_TAREA FK02_PARAMETRO_RELACION_TAREA; Type: FK CONSTRAINT; Schema: sgdp; Owner: sgdp
--

ALTER TABLE ONLY sgdp."SGDP_PARAMETRO_RELACION_TAREA"
    ADD CONSTRAINT "FK02_PARAMETRO_RELACION_TAREA" FOREIGN KEY ("ID_PARAM_TAREA") REFERENCES sgdp."SGDP_PARAMETRO_DE_TAREA"("ID_PARAM_TAREA");


--
-- Name: SGDP_PROCESOS FK02_PROCESOS; Type: FK CONSTRAINT; Schema: sgdp; Owner: sgdp
--

ALTER TABLE ONLY sgdp."SGDP_PROCESOS"
    ADD CONSTRAINT "FK02_PROCESOS" FOREIGN KEY ("ID_UNIDAD") REFERENCES sgdp."SGDP_UNIDADES"("ID_UNIDAD");


--
-- Name: SGDP_REFERENCIAS_DE_TAREAS FK02_REFERENCIAS_DE_TAREAS; Type: FK CONSTRAINT; Schema: sgdp; Owner: sgdp
--

ALTER TABLE ONLY sgdp."SGDP_REFERENCIAS_DE_TAREAS"
    ADD CONSTRAINT "FK02_REFERENCIAS_DE_TAREAS" FOREIGN KEY ("ID_TAREA_SIGUIENTE") REFERENCES sgdp."SGDP_TAREAS"("ID_TAREA");


--
-- Name: SGDP_RESPONSABILIDAD_TAREA FK02_RESPONSABILIDAD_TAREA; Type: FK CONSTRAINT; Schema: sgdp; Owner: sgdp
--

ALTER TABLE ONLY sgdp."SGDP_RESPONSABILIDAD_TAREA"
    ADD CONSTRAINT "FK02_RESPONSABILIDAD_TAREA" FOREIGN KEY ("ID_RESPONSABILIDAD") REFERENCES sgdp."SGDP_RESPONSABILIDAD"("ID_RESPONSABILIDAD");


--
-- Name: SGDP_SOLICITUD_CREACION_EXP FK02_SOLICITUD_CREACION_EXP; Type: FK CONSTRAINT; Schema: sgdp; Owner: sgdp
--

ALTER TABLE ONLY sgdp."SGDP_SOLICITUD_CREACION_EXP"
    ADD CONSTRAINT "FK02_SOLICITUD_CREACION_EXP" FOREIGN KEY ("ID_ESTADO_SOLICITUD_CREACION_EXP") REFERENCES sgdp."SGDP_ESTADO_SOLICITUD_CREACION_EXP"("ID_ESTADO_SOLICITUD_CREACION_EXP");


--
-- Name: SGDP_TAREAS FK02_TAREAS; Type: FK CONSTRAINT; Schema: sgdp; Owner: sgdp
--

ALTER TABLE ONLY sgdp."SGDP_TAREAS"
    ADD CONSTRAINT "FK02_TAREAS" FOREIGN KEY ("ID_ETAPA") REFERENCES sgdp."SGDP_ETAPAS"("ID_ETAPA");


--
-- Name: SGDP_TAREAS_INICIA_PROCESOS FK02_TAREAS_INICIA_PROCESOS; Type: FK CONSTRAINT; Schema: sgdp; Owner: sgdp
--

ALTER TABLE ONLY sgdp."SGDP_TAREAS_INICIA_PROCESOS"
    ADD CONSTRAINT "FK02_TAREAS_INICIA_PROCESOS" FOREIGN KEY ("ID_PROCESO") REFERENCES sgdp."SGDP_PROCESOS"("ID_PROCESO");


--
-- Name: SGDP_TAREAS_ROLES FK02_TAREAS_ROLES; Type: FK CONSTRAINT; Schema: sgdp; Owner: sgdp
--

ALTER TABLE ONLY sgdp."SGDP_TAREAS_ROLES"
    ADD CONSTRAINT "FK02_TAREAS_ROLES" FOREIGN KEY ("ID_ROL") REFERENCES sgdp."SGDP_ROLES"("ID_ROL");


--
-- Name: SGDP_USUARIOS_ROLES FK02_USUARIOS_ROLES; Type: FK CONSTRAINT; Schema: sgdp; Owner: sgdp
--

ALTER TABLE ONLY sgdp."SGDP_USUARIOS_ROLES"
    ADD CONSTRAINT "FK02_USUARIOS_ROLES" FOREIGN KEY ("ID_UNIDAD") REFERENCES sgdp."SGDP_UNIDADES"("ID_UNIDAD");


--
-- Name: SGDP_VALOR_PARAMETRO_DE_TAREA FK02_VALOR_PARAMETRO_DE_TAREA; Type: FK CONSTRAINT; Schema: sgdp; Owner: sgdp
--

ALTER TABLE ONLY sgdp."SGDP_VALOR_PARAMETRO_DE_TAREA"
    ADD CONSTRAINT "FK02_VALOR_PARAMETRO_DE_TAREA" FOREIGN KEY ("ID_INSTANCIA_DE_TAREA") REFERENCES sgdp."SGDP_INSTANCIAS_DE_TAREAS"("ID_INSTANCIA_DE_TAREA");


--
-- Name: SGDP_VINCULACION_EXP FK02_VINCULACION_EXP; Type: FK CONSTRAINT; Schema: sgdp; Owner: sgdp
--

ALTER TABLE ONLY sgdp."SGDP_VINCULACION_EXP"
    ADD CONSTRAINT "FK02_VINCULACION_EXP" FOREIGN KEY ("ID_INSTANCIA_DE_PROCESO_ANTECESOR") REFERENCES sgdp."SGDP_INSTANCIAS_DE_PROCESOS"("ID_INSTANCIA_DE_PROCESO");


--
-- Name: SGDP_ARCHIVOS_INST_DE_TAREA FK03_ARCHIVOS_INST_DE_TAREA; Type: FK CONSTRAINT; Schema: sgdp; Owner: sgdp
--

ALTER TABLE ONLY sgdp."SGDP_ARCHIVOS_INST_DE_TAREA"
    ADD CONSTRAINT "FK03_ARCHIVOS_INST_DE_TAREA" FOREIGN KEY ("ID_ARCHIVOS_INST_DE_TAREA_METADATA") REFERENCES sgdp."SGDP_ARCHIVOS_INST_DE_TAREA_METADATA"("ID_ARCHIVOS_INST_DE_TAREA_METADATA");


--
-- Name: SGDP_HISTORICO_DE_INST_DE_TAREAS FK03_HISTORICO_DE_INST_DE_TAREAS; Type: FK CONSTRAINT; Schema: sgdp; Owner: sgdp
--

ALTER TABLE ONLY sgdp."SGDP_HISTORICO_DE_INST_DE_TAREAS"
    ADD CONSTRAINT "FK03_HISTORICO_DE_INST_DE_TAREAS" FOREIGN KEY ("ID_ACCION_HISTORICO_INST_DE_TAREA") REFERENCES sgdp."SGDP_ACCIONES_HIST_INST_DE_TAREAS"("ID_ACCION_HISTORICO_INST_DE_TAREA");


--
-- Name: SGDP_HISTORICO_SOLICITUD_CREACION_EXP FK03_HISTORICO_SOLICITUD_CREACION_EXP; Type: FK CONSTRAINT; Schema: sgdp; Owner: sgdp
--

ALTER TABLE ONLY sgdp."SGDP_HISTORICO_SOLICITUD_CREACION_EXP"
    ADD CONSTRAINT "FK03_HISTORICO_SOLICITUD_CREACION_EXP" FOREIGN KEY ("ID_ESTADO_SOLICITUD_CREACION_EXP") REFERENCES sgdp."SGDP_ESTADO_SOLICITUD_CREACION_EXP"("ID_ESTADO_SOLICITUD_CREACION_EXP");


--
-- Name: SGDP_INSTANCIAS_DE_PROCESOS FK03_INSTANCIAS_DE_PROCESOS; Type: FK CONSTRAINT; Schema: sgdp; Owner: sgdp
--

ALTER TABLE ONLY sgdp."SGDP_INSTANCIAS_DE_PROCESOS"
    ADD CONSTRAINT "FK03_INSTANCIAS_DE_PROCESOS" FOREIGN KEY ("ID_UNIDAD") REFERENCES sgdp."SGDP_UNIDADES"("ID_UNIDAD");


--
-- Name: SGDP_INSTANCIAS_DE_TAREAS FK03_INSTANCIAS_DE_TAREAS; Type: FK CONSTRAINT; Schema: sgdp; Owner: sgdp
--

ALTER TABLE ONLY sgdp."SGDP_INSTANCIAS_DE_TAREAS"
    ADD CONSTRAINT "FK03_INSTANCIAS_DE_TAREAS" FOREIGN KEY ("ID_ESTADO_DE_TAREA") REFERENCES sgdp."SGDP_ESTADOS_DE_TAREAS"("ID_ESTADO_DE_TAREA");


--
-- Name: SGDP_INSTANCIAS_DE_TAREAS_LIBRES FK03_INSTANCIAS_DE_TAREAS_LIBRES; Type: FK CONSTRAINT; Schema: sgdp; Owner: sgdp
--

ALTER TABLE ONLY sgdp."SGDP_INSTANCIAS_DE_TAREAS_LIBRES"
    ADD CONSTRAINT "FK03_INSTANCIAS_DE_TAREAS_LIBRES" FOREIGN KEY ("ID_TIPO_DE_TAREA_LIBRE") REFERENCES sgdp."SGDP_TIPOS_DE_TAREAS_LIBRES"("ID_TIPO_DE_TAREA_LIBRE");


--
-- Name: SGDP_SOLICITUD_CREACION_EXP FK03_SOLICITUD_CREACION_EXP; Type: FK CONSTRAINT; Schema: sgdp; Owner: sgdp
--

ALTER TABLE ONLY sgdp."SGDP_SOLICITUD_CREACION_EXP"
    ADD CONSTRAINT "FK03_SOLICITUD_CREACION_EXP" FOREIGN KEY ("ID_PROCESO") REFERENCES sgdp."SGDP_PROCESOS"("ID_PROCESO");


--
-- Name: SGDP_HISTORICO_SOLICITUD_CREACION_EXP FK04_HISTORICO_SOLICITUD_CREACION_EXP; Type: FK CONSTRAINT; Schema: sgdp; Owner: sgdp
--

ALTER TABLE ONLY sgdp."SGDP_HISTORICO_SOLICITUD_CREACION_EXP"
    ADD CONSTRAINT "FK04_HISTORICO_SOLICITUD_CREACION_EXP" FOREIGN KEY ("ID_PROCESO") REFERENCES sgdp."SGDP_PROCESOS"("ID_PROCESO");


--
-- Name: SGDP_INSTANCIAS_DE_PROCESOS FK04_INSTANCIAS_DE_PROCESOS; Type: FK CONSTRAINT; Schema: sgdp; Owner: sgdp
--

ALTER TABLE ONLY sgdp."SGDP_INSTANCIAS_DE_PROCESOS"
    ADD CONSTRAINT "FK04_INSTANCIAS_DE_PROCESOS" FOREIGN KEY ("ID_INSTANCIA_DE_PROCESO_PADRE") REFERENCES sgdp."SGDP_INSTANCIAS_DE_PROCESOS"("ID_INSTANCIA_DE_PROCESO");


--
-- Name: SGDP_SOLICITUD_CREACION_EXP FK04_SOLICITUD_CREACION_EXP; Type: FK CONSTRAINT; Schema: sgdp; Owner: sgdp
--

ALTER TABLE ONLY sgdp."SGDP_SOLICITUD_CREACION_EXP"
    ADD CONSTRAINT "FK04_SOLICITUD_CREACION_EXP" FOREIGN KEY ("ID_AUTOR") REFERENCES sgdp."SGDP_AUTORES"("ID_AUTOR");


--
-- Name: SGDP_HISTORICO_SOLICITUD_CREACION_EXP FK05_HISTORICO_SOLICITUD_CREACION_EXP; Type: FK CONSTRAINT; Schema: sgdp; Owner: sgdp
--

ALTER TABLE ONLY sgdp."SGDP_HISTORICO_SOLICITUD_CREACION_EXP"
    ADD CONSTRAINT "FK05_HISTORICO_SOLICITUD_CREACION_EXP" FOREIGN KEY ("ID_AUTOR") REFERENCES sgdp."SGDP_AUTORES"("ID_AUTOR");


--
-- Name: SGDP_INSTANCIAS_DE_PROCESOS FK05_INSTANCIAS_DE_PROCESOS; Type: FK CONSTRAINT; Schema: sgdp; Owner: sgdp
--

ALTER TABLE ONLY sgdp."SGDP_INSTANCIAS_DE_PROCESOS"
    ADD CONSTRAINT "FK05_INSTANCIAS_DE_PROCESOS" FOREIGN KEY ("ID_ACCESO") REFERENCES sgdp."SGDP_ACCESOS"("ID_ACCESO");


--
-- Name: SGDP_INSTANCIAS_DE_PROCESOS FK06_INSTANCIA_PROCESO_METADATA; Type: FK CONSTRAINT; Schema: sgdp; Owner: sgdp
--

ALTER TABLE ONLY sgdp."SGDP_INSTANCIAS_DE_PROCESOS"
    ADD CONSTRAINT "FK06_INSTANCIA_PROCESO_METADATA" FOREIGN KEY ("ID_INSTANCIA_PROCESO_METADATA") REFERENCES sgdp."SGDP_INSTANCIA_PROCESO_METADATA"("ID_INSTANCIA_PROCESO_METADATA");


--
-- Name: SGDP_INSTANCIAS_DE_PROCESOS FK07_TIPOS; Type: FK CONSTRAINT; Schema: sgdp; Owner: sgdp
--

ALTER TABLE ONLY sgdp."SGDP_INSTANCIAS_DE_PROCESOS"
    ADD CONSTRAINT "FK07_TIPOS" FOREIGN KEY ("ID_TIPO") REFERENCES sgdp."SGDP_TIPOS"("ID_TIPO");


--
-- Name: SGDP_CARGO_USUARIO_ROL SGDP_CARGO_USUARIO_ROL_ID_CARGO_fkey; Type: FK CONSTRAINT; Schema: sgdp; Owner: sgdp
--

ALTER TABLE ONLY sgdp."SGDP_CARGO_USUARIO_ROL"
    ADD CONSTRAINT "SGDP_CARGO_USUARIO_ROL_ID_CARGO_fkey" FOREIGN KEY ("ID_CARGO") REFERENCES sgdp."SGDP_CARGO"("ID_CARGO");


--
-- Name: SGDP_CARGO_USUARIO_ROL SGDP_CARGO_USUARIO_ROL_ID_USUARIO_ROL_fkey; Type: FK CONSTRAINT; Schema: sgdp; Owner: sgdp
--

ALTER TABLE ONLY sgdp."SGDP_CARGO_USUARIO_ROL"
    ADD CONSTRAINT "SGDP_CARGO_USUARIO_ROL_ID_USUARIO_ROL_fkey" FOREIGN KEY ("ID_USUARIO_ROL") REFERENCES sgdp."SGDP_USUARIOS_ROLES"("ID_USUARIO_ROL");


--
-- Name: SGDP_TEXTO_PARAMETRO_DE_TAREA SGDP_TEXTO_PARAMETRO_DE_TAREA_ID_PARAM_TAREA_fkey; Type: FK CONSTRAINT; Schema: sgdp; Owner: sgdp
--

ALTER TABLE ONLY sgdp."SGDP_TEXTO_PARAMETRO_DE_TAREA"
    ADD CONSTRAINT "SGDP_TEXTO_PARAMETRO_DE_TAREA_ID_PARAM_TAREA_fkey" FOREIGN KEY ("ID_PARAM_TAREA") REFERENCES sgdp."SGDP_PARAMETRO_DE_TAREA"("ID_PARAM_TAREA");


--
-- Name: SGDP_SEGUIMIENTO_INTANCIA_PROCESOS fk_sgdp_instancia_de_proceso.ID_INSTANCIA_PROCESO; Type: FK CONSTRAINT; Schema: sgdp; Owner: sgdp
--

ALTER TABLE ONLY sgdp."SGDP_SEGUIMIENTO_INTANCIA_PROCESOS"
    ADD CONSTRAINT "fk_sgdp_instancia_de_proceso.ID_INSTANCIA_PROCESO" FOREIGN KEY ("ID_INSTANCIA_PROCESO") REFERENCES sgdp."SGDP_INSTANCIAS_DE_PROCESOS"("ID_INSTANCIA_DE_PROCESO");


--
-- PostgreSQL database dump complete
--

