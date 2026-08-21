# DU/IA - Parte 3: informe y lectura critica

## Declaracion transparente

- Herramienta de IA utilizada: OpenCode / OpenAI, modelo `openai/gpt-5.6-terra`.
- Uso: asistencia para organizar el informe, separar expectativas de evidencia y explicar riesgos frecuentes de SQL.
- El contenido generado requiere validacion del estudiante frente al esquema real y los resultados reales de la practica.

## Prompt utilizado

> Redactar en espanol un informe de concurrencia con tres escenarios del laboratorio Food Store. Cada seccion debe contener orden exacto de comandos, explicacion basada en PostgreSQL, resultado esperado marcado como esperado y campos de observacion real marcados PENDIENTE DE EJECUCION. Agregar una lectura critica de un UPDATE que desactiva todas las peliculas y de un DELETE basado en NOT IN que falla si la subconsulta contiene NULL; proponer una correccion segura sin inventar columnas del esquema.

## Aporte de IA y control humano

La IA explico que la condicion de baja de cartelera necesita una regla de negocio verificable, por ejemplo una fecha de fin validada en el esquema, y que `NOT EXISTS` evita la semantica de tres valores de `NOT IN` con `NULL`. El estudiante debe sustituir los campos ilustrativos por nombres confirmados de su propia base antes de ejecutar.

## Verificacion real

Estado actual: **PENDIENTE DE EJECUCION**. Solo se hizo revision estatica de documentos y SQL, sin ejecucion de base de datos ni evidencia capturada.

Completar despues de ejecutar:

```text
Esquema/tabla/columnas validados para el ejercicio critico:
Evidencia real incorporada al informe:
Cambios realizados tras la revision docente:
```
