# Teleports de pozo

Escena reutilizable: `assets/teleports/teleport.tscn`.

## Configuración

1. Instancia dos teleports dentro del mismo nivel.
2. En el inspector de A, asigna B a `destination`. Para permitir volver, asigna
   A como `destination` de B también. Los enlaces son direccionales.
3. Activa **Editable Children** en cada instancia para ajustar sus marcadores:
   - `EntryPoint`: posición de los pies al entrar en el pozo.
   - `InsidePoint`: posición oculta dentro del pozo, desde donde sale el salto.
   - `ExitPoint`: posición de los pies al aterrizar. Colócalo sobre suelo libre,
     preferiblemente fuera del detector.
   - `TeleportCamera`: posición de la cámara fija del pozo.
   - `CameraFocus`: punto hacia el que mira esa cámara al iniciar el nivel.
4. Sustituye la malla cilíndrica de prototipo por el pozo cuando esté disponible.
   Mantén `CollisionShape3D` directamente bajo el `Area3D`, activado. El detector
   usa la capa del jugador; no necesita una colisión sólida en el hueco.

## Secuencia

Al entrar, se selecciona la cámara del origen. El personaje se centra durante
0,25 segundos, baja durante 0,4 segundos y se oculta. La cámara espera
`source_hold` segundos (2 por defecto). Después corta a la cámara del destino,
espera `destination_hold` (0,35) y muestra al personaje saliendo con una parábola
hasta `ExitPoint`. Se mantiene ese plano durante `landing_hold` (0,3) y se
restaura la cámara que estaba activa antes de entrar.

El destino controla `jump_duration` (1 segundo) y `jump_height` (2 unidades de
elevación añadida a la interpolación entre el interior y la salida). El recorrido
es dirigido, no un salto controlable: deja su trayectoria y aterrizaje libres de
obstáculos. Durante el viaje se bloquean las acciones, se suspenden la gravedad y
las colisiones del personaje y no recibe daño. El mundo y las pociones continúan;
el menú de pausa sí detiene la secuencia.

El bloqueo de llegada evita volver a entrar automáticamente si `ExitPoint` queda
dentro de un detector. Hay que salir del área para volver a activarlo. Un teleport
sin destino válido no inicia ninguna secuencia. Si desaparece un extremo durante
el viaje, se devuelve al personaje a su posición de entrada y se restauran sus
controles, visibilidad, animación, colisiones y cámara.

## Pruebas

- Abre `scenes/tests/teleport_test.tscn` y pulsa F6: contiene dos pozos enlazados,
  suelo y jugador. Acércate a cualquiera de los dos cilindros.
- Regresión automática con Godot 4.7.2:
  `godot --headless --path . --script res://scenes/tests/teleport_sequence_test.gd`.
  Comprueba detección, cámaras, pausa, salto, aterrizaje y recuperación tras
  eliminar el destino durante el viaje.
