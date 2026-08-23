# Trueque · Networking de arrancada

Herramienta de ICONEialabs para conectar comunidades por **asimetría útil**: cruza lo que
cada persona necesita contra lo que ofrecen las demás, no por parecido de sector o cargo.

La premisa: todo lo que se pone en la mesa arranca **sin costo**. Lo que venga después lo
deciden las dos personas.

## Los dos enlaces

| Qué | Ruta | Quién entra |
|---|---|---|
| Formulario | `/trueque/?c=<comunidad>` | Público, sin registro |
| Panel | `/trueque/panel/` | Solo con contraseña |

El parámetro `c` separa las rondas. Una comunidad nueva no necesita despliegue: basta con
cambiar el enlace.

```
/trueque/?c=gofest      -> GoFest 2026
/trueque/?c=managers    -> Fundación Managers
/trueque/?c=lo-que-sea  -> se crea sola, el título sale del slug
```

Los nombres bonitos de comunidades conocidas están en el objeto `NOMBRES` dentro de
`trueque/index.html`. Sin entrada en esa lista, el título se arma desde el slug.

## Contraseña del panel

`Trueque-ICONE-2026`

Vive únicamente dentro de las funciones de Postgres, nunca en el HTML. Para cambiarla hay que
reemplazarla en las cinco funciones que la validan (`get_trueque`, `get_trueque_comunidades`,
`delete_trueque`, `save_trueque_matches`, `get_trueque_matches`).

## El cerebro

El emparejamiento lo hace Google Gemini desde el navegador del panel. La clave se pide una vez
en **Ajustes**, se guarda en el `localStorage` de ese equipo y no entra al repositorio ni viaja
a Supabase. Se saca gratis en https://aistudio.google.com/apikey

Sin clave también funciona: **Copiar prompt**, pegarlo en Claude o en el chat que se use, y
devolver la respuesta con **Pegar resultado**.

Al modelo solo se le mandan nombre, necesidad y oferta con identificadores cortos (`p1`, `p2`).
Correos y celulares nunca salen del navegador.

### Lo que el motor tiene prohibido

El prompt bloquea explícitamente el error que hunde a las apps de matchmaking de eventos:
emparejar por similitud y llamarlo complementariedad. Reglas duras:

- Un match existe solo si la oferta de B resuelve la necesidad de A. Parecerse de sector,
  cargo o etapa no cuenta.
- Bajo 50 puntos no se reporta. Cero matches es mejor que un match tibio.
- Prohibido escribir razones genéricas. Si la razón sirve para cualquier otra pareja, está mal.
- A quien nadie pueda resolverle, no se le fuerza una reunión: va a **Vacíos de la comunidad**,
  que dice qué oferta le falta a la red.

El panel además descarta en el cliente los pares repetidos en sentido contrario y todo lo que
venga bajo 50.

## Base de datos

Proyecto Supabase `docadmin` (`nvgkhdrrxqdgxktfkioa`). Migración
`icone_trueque_networking_v1`, aditiva: no toca ninguna tabla previa.

Las tablas `icone_trueque` e `icone_trueque_matches` están cerradas al rol `anon`. Todo pasa
por funciones `security definer`:

| Función | Quién | Para qué |
|---|---|---|
| `submit_trueque` | público | Única escritura. Valida y deduplica por correo. |
| `get_trueque_conteo` | público | Contador de la ronda. Cero datos personales. |
| `get_trueque` | con clave | Listado completo |
| `get_trueque_comunidades` | con clave | Rondas activas |
| `delete_trueque` | con clave | Borrar una ficha |
| `save_trueque_matches` | con clave | Guardar el análisis |
| `get_trueque_matches` | con clave | Leer el análisis con los datos de ambas personas |

Reenviar el formulario con el mismo correo **actualiza** la ficha en vez de duplicarla, así que
la persona puede corregirse desde "Editar mis respuestas".

## Límites conocidos de esta fase

- Los **vacíos de la comunidad** viven en el `localStorage` del panel, no en la base. Si se
  cambia de equipo hay que volver a correr el análisis.
- No hay límite de envíos por IP. Para una ronda abierta y masiva habría que agregarlo.
- El análisis se probó cómodo hasta unas 60 fichas por ronda. Más arriba conviene subir a
  `gemini-2.5-pro` o partir la comunidad.
- El envío de las conexiones es manual y a propósito: el panel arma el texto con **Copiar
  presentación** y la persona lo manda. La automatización es de la fase siguiente.
