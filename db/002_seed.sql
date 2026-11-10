-- FICO - datos iniciales. Correr UNA sola vez, despues de 001_schema.sql.
-- Todo lo marcado EDITAR es un ejemplo: cambialo por tu lista real.

-- telegram_chat_id = 0 es temporal; se actualiza en el hito C con tu chat_id real.
insert into users (telegram_chat_id, nombre) values (0, 'Rodri');

-- EDITAR: checklist base por area
insert into checklist_items (user_id, area, titulo, franja, orden)
select u.id, v.area, v.titulo, v.franja, v.orden
from users u, (values
  ('Espiritual',   'Oración de la mañana',        'mañana', 1),
  ('Espiritual',   'Lectura (10 min)',            'mañana', 2),
  ('Vida',         'Tender la cama',              'mañana', 1),
  ('Vida',         'Revisar pendientes del día',  'mañana', 2),
  ('Vida',         'Dormir antes de las 23:30',   'noche',  3),
  ('Gym',          'Entrenar',                    'tarde',  1),
  ('Gym',          'Estirar 5 min',               'tarde',  2),
  ('Alimentación', 'Desayuno con proteína',       'mañana', 1),
  ('Alimentación', '2 litros de agua',            'tarde',  2),
  ('Alimentación', 'Cena sin ultraprocesados',    'noche',  3)
) as v(area, titulo, franja, orden);

-- Check-ins. El ultimo del dia (22:00) es el cierre con todas las areas.
insert into checkin_slots (user_id, hora, areas)
select u.id, v.hora::time, v.areas
from users u, (values
  ('07:00', array['Espiritual', 'Vida']),
  ('14:00', array['Alimentación', 'Vida']),
  ('20:00', array['Gym', 'Alimentación']),
  ('22:00', array['Espiritual', 'Vida', 'Gym', 'Alimentación'])
) as v(hora, areas);

-- EDITAR: rutina de gym de ejemplo (1 = lunes ... 7 = domingo)
insert into gym_plan (user_id, dia_semana, grupo, ejercicio, series, reps, peso_obj, orden)
select u.id, v.dia, v.grupo, v.ejercicio, v.series, v.reps, v.peso, v.orden
from users u, (values
  (1, 'Pecho y tríceps',  'Press de banca',          4, '8-10',  60.0, 1),
  (1, 'Pecho y tríceps',  'Press inclinado mancuerna', 3, '10',  22.5, 2),
  (1, 'Pecho y tríceps',  'Extensión de tríceps',    3, '12',    25.0, 3),
  (2, 'Espalda y bíceps', 'Jalón al pecho',          4, '10',    55.0, 1),
  (2, 'Espalda y bíceps', 'Remo con barra',          3, '8-10',  50.0, 2),
  (2, 'Espalda y bíceps', 'Curl de bíceps',          3, '12',    12.5, 3),
  (4, 'Pierna',           'Sentadilla',              4, '8',     70.0, 1),
  (4, 'Pierna',           'Prensa',                  3, '10',   120.0, 2),
  (4, 'Pierna',           'Curl femoral',            3, '12',    35.0, 3),
  (5, 'Hombro y core',    'Press militar',           4, '8-10',  35.0, 1),
  (5, 'Hombro y core',    'Elevaciones laterales',   3, '12',     8.0, 2),
  (5, 'Hombro y core',    'Plancha',                 3, '45 s',  null, 3)
) as v(dia, grupo, ejercicio, series, reps, peso, orden);
