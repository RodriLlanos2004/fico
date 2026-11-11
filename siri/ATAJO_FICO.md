# Atajos de Siri para FICO

Dos atajos en la app **Atajos** del iPhone. Tiempo: unos 15 minutos.

## Antes de empezar

Necesitas dos datos:

- **URL base**: la línea "Publico" que imprime `infra/local-up.sh`, por ejemplo `https://tu-nombre.ngrok-free.app`.
- **Token**: el valor de `SIRI_TOKEN` en `infra/.env.local` (ábrelo con `notepad infra\.env.local`).
  Pásalo al iPhone por una nota de iCloud o AirDrop; no lo mandes por chats.

Para no editar cada acción cuando cambie la URL, cada atajo empieza con una acción **Texto** que la guarda.

## Atajo 1: "FICO"

Crea un atajo nuevo, nómbralo exactamente `FICO` y agrega estas acciones en orden:

1. **Texto**: escribe la URL base, sin diagonal al final.
2. **Establecer variable**: nombre `Base`, valor el Texto anterior.
3. **Dictar texto**: idioma Español (México), "Dejar de escuchar": Después de una pausa.
4. **Obtener contenido de URL**:
   - URL: variable `Base` seguida de `/webhook/fico`
   - Método: **POST**
   - Encabezados: agrega uno. Clave `Authorization`, valor `Bearer ` (con espacio) seguido del token.
   - Cuerpo de la solicitud: **JSON**, con dos campos de tipo Texto:
     - `texto`: la variable **Texto dictado**
     - `canal`: `siri`
5. **Obtener diccionario de la entrada** (entrada: Contenido de URL).
6. **Establecer variable**: nombre `Respuesta`, valor el Diccionario.
7. **Obtener valor del diccionario**: Obtener **Valor** de la clave `acciones_locales` en `Respuesta`.
8. **Repetir con cada elemento** (de Valor del diccionario). Dentro del ciclo:
   1. **Obtener valor del diccionario**: clave `tipo` en **Elemento de repetición**.
   2. **Si** Valor del diccionario **es** `alarma`:
      - **Obtener valor del diccionario**: clave `hora` en Elemento de repetición.
      - **Obtener valor del diccionario**: clave `etiqueta` en Elemento de repetición.
      - **Crear alarma**: hora = el valor de `hora`, etiqueta = el valor de `etiqueta`.
   3. **De lo contrario**:
      - **Obtener valor del diccionario**: clave `minutos` en Elemento de repetición.
      - **Iniciar temporizador**: duración = el valor de `minutos`, unidad **minutos**.
   4. **Fin de Si**.
9. **Fin de Repetir**.
10. **Obtener valor del diccionario**: clave `respuesta` en `Respuesta`.
11. **Leer texto**: el valor anterior. En los ajustes de la acción elige idioma Español (México).

En los detalles del atajo (icono de información) desactiva "Mostrar al ejecutar" donde aparezca, para que
no pida confirmación cada vez. La primera vez iOS pedirá permiso para conectarse a la URL y para crear
alarmas: elige **Permitir siempre**.

## Atajo 2: "FICO acciones"

Sirve para aplicar en el iPhone lo que pediste por Telegram (alarmas y temporizadores). Nómbralo
exactamente `FICO acciones`, porque el botón de Telegram lo abre por ese nombre.

La forma rápida: mantén presionado el atajo `FICO`, elige **Duplicar**, renombra la copia y cambia esto:

- Borra la acción **Dictar texto**.
- En **Obtener contenido de URL**: URL = `Base` seguida de `/webhook/fico/acciones-pendientes`,
  método **GET**, sin cuerpo. El encabezado `Authorization` queda igual.

El resto (diccionario, ciclo de alarmas y temporizadores, leer la respuesta) no cambia.

## Cómo se usa

- Di "Oye Siri, FICO", espera el tono y dicta: "¿qué tengo pendiente?", "ponme alarma a las 6:30 para gym".
  Siri no acepta la orden y la pregunta en una sola frase; siempre son dos pasos.
- Por Telegram, cuando pidas una alarma o temporizador, FICO contesta con el botón
  **Aplicar en el iPhone**, que abre el atajo `FICO acciones`.

## Accesos rápidos

- **Botón de Acción** (iPhone 15 Pro o posterior; el 14 Pro Max no lo tiene): Ajustes > Botón de Acción > Atajo > FICO.
- **Toque atrás** (sí funciona en el 14 Pro Max): Ajustes > Accesibilidad > Tocar > Tocar atrás >
  Tocar dos veces > baja hasta Atajos > FICO.
- **Pantalla bloqueada** (iOS 18 o posterior): mantén presionada la pantalla bloqueada > Personalizar >
  Pantalla bloqueada > toca uno de los dos botones de abajo > Atajo > FICO.
- **Centro de Control** (iOS 18 o posterior): desliza para abrirlo > mantén presionado un espacio vacío >
  Agregar un control > Atajo > FICO.
- **Widget**: mantén presionada la pantalla de inicio > Editar > Agregar widget > Atajos > elige el
  tamaño pequeño > toca el widget y selecciona FICO.

## Si algo falla

| Síntoma | Causa probable |
|---|---|
| "No se pudo conectar al servidor" | La laptop está apagada o la URL base ya cambió |
| Siri no dice nada y el atajo termina | Token mal copiado: el servidor responde 403 sin contenido |
| Lee la respuesta pero no crea la alarma | Falta el permiso de alarmas, o la clave `hora` quedó mal escrita |
| El botón de Telegram abre una página en blanco | Toca "Abrir en Safari"; el navegador interno de Telegram a veces no abre atajos |
