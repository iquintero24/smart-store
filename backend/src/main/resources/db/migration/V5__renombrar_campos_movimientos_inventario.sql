ALTER TABLE movimientos_inventario
  RENAME COLUMN cantidad_existencia TO delta_existencia;

ALTER TABLE movimientos_inventario
  RENAME COLUMN cantidad_reservada TO delta_reservada;
