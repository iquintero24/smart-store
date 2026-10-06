-- ============================================================
-- V13 - REFORZAR INTEGRIDAD DEL MODELO
-- Smart Store
-- ============================================================


-- ============================================================
-- 1. FUNCION:
-- Validar que una variante configurada para una sede pertenezca
-- al mismo comercio de la sede.
--
-- Evita:
--
-- Sede del Comercio A
--        +
-- Producto del Comercio B
-- ============================================================

CREATE OR REPLACE FUNCTION validar_variante_sede_mismo_comercio()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
comercio_sede BIGINT;
    comercio_producto BIGINT;
BEGIN

SELECT s.comercio_id
INTO comercio_sede
FROM sedes s
WHERE s.id = NEW.sede_id;

SELECT c.comercio_id
INTO comercio_producto
FROM variantes_producto vp
       JOIN productos p
            ON p.id = vp.producto_id
       JOIN categorias c
            ON c.id = p.categoria_id
WHERE vp.id = NEW.variante_producto_id;

IF comercio_sede IS DISTINCT FROM comercio_producto THEN
        RAISE EXCEPTION
            'La variante del producto no pertenece al mismo comercio de la sede';
END IF;

RETURN NEW;
END;
$$;


CREATE TRIGGER trg_validar_variante_sede_mismo_comercio
  BEFORE INSERT OR UPDATE
                     ON variantes_producto_sede
                     FOR EACH ROW
                     EXECUTE FUNCTION validar_variante_sede_mismo_comercio();


-- ============================================================
-- 2. FUNCION:
-- Validar que el cliente de un pedido pertenezca al mismo
-- comercio de la sede donde se realiza el pedido.
-- ============================================================

CREATE OR REPLACE FUNCTION validar_pedido_cliente_comercio()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
comercio_sede BIGINT;
    comercio_cliente BIGINT;
BEGIN

SELECT comercio_id
INTO comercio_sede
FROM sedes
WHERE id = NEW.sede_id;

SELECT comercio_id
INTO comercio_cliente
FROM clientes
WHERE id = NEW.cliente_id;

IF comercio_sede IS DISTINCT FROM comercio_cliente THEN
        RAISE EXCEPTION
            'El cliente no pertenece al comercio de la sede del pedido';
END IF;

RETURN NEW;
END;
$$;


CREATE TRIGGER trg_validar_pedido_cliente_comercio
  BEFORE INSERT OR UPDATE
                     ON pedidos
                     FOR EACH ROW
                     EXECUTE FUNCTION validar_pedido_cliente_comercio();


-- ============================================================
-- 3. FUNCION:
-- Validar que los productos agregados a un pedido pertenezcan
-- a la misma sede del pedido.
-- ============================================================

CREATE OR REPLACE FUNCTION validar_detalle_pedido_sede()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
sede_pedido BIGINT;
    sede_variante BIGINT;
BEGIN

SELECT sede_id
INTO sede_pedido
FROM pedidos
WHERE id = NEW.pedido_id;

SELECT sede_id
INTO sede_variante
FROM variantes_producto_sede
WHERE id = NEW.variante_producto_sede_id;

IF sede_pedido IS DISTINCT FROM sede_variante THEN
        RAISE EXCEPTION
            'La variante del producto no pertenece a la sede del pedido';
END IF;

RETURN NEW;
END;
$$;


CREATE TRIGGER trg_validar_detalle_pedido_sede
  BEFORE INSERT OR UPDATE
                     ON detalles_pedido
                     FOR EACH ROW
                     EXECUTE FUNCTION validar_detalle_pedido_sede();


-- ============================================================
-- 4. FUNCION:
-- Validar que los productos registrados en una compra
-- pertenezcan a la misma sede de la compra.
-- ============================================================

CREATE OR REPLACE FUNCTION validar_detalle_compra_sede()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
sede_compra BIGINT;
    sede_variante BIGINT;
BEGIN

SELECT sede_id
INTO sede_compra
FROM compras
WHERE id = NEW.compra_id;

SELECT sede_id
INTO sede_variante
FROM variantes_producto_sede
WHERE id = NEW.variante_producto_sede_id;

IF sede_compra IS DISTINCT FROM sede_variante THEN
        RAISE EXCEPTION
            'La variante del producto no pertenece a la sede de la compra';
END IF;

RETURN NEW;
END;
$$;


CREATE TRIGGER trg_validar_detalle_compra_sede
  BEFORE INSERT OR UPDATE
                     ON detalles_compra
                     FOR EACH ROW
                     EXECUTE FUNCTION validar_detalle_compra_sede();


-- ============================================================
-- 5. FUNCION:
-- Una variante no puede tener dos valores diferentes
-- pertenecientes al mismo atributo.
--
-- Incorrecto:
--
-- Coca-Cola variante X
-- Color = Rojo
-- Color = Azul
--
-- Correcto:
--
-- Color = Rojo
-- Tamaño = Grande
-- ============================================================

CREATE OR REPLACE FUNCTION validar_un_valor_por_atributo()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
atributo_nuevo BIGINT;
BEGIN

SELECT atributo_id
INTO atributo_nuevo
FROM valores_atributo
WHERE id = NEW.valor_atributo_id;

IF EXISTS (
        SELECT 1
          FROM variantes_valores_atributo vva
          JOIN valores_atributo va
            ON va.id = vva.valor_atributo_id
         WHERE vva.variante_producto_id = NEW.variante_producto_id
           AND va.atributo_id = atributo_nuevo
           AND vva.valor_atributo_id <> NEW.valor_atributo_id
    ) THEN

        RAISE EXCEPTION
            'La variante ya tiene asignado un valor para este atributo';

END IF;

RETURN NEW;
END;
$$;


CREATE TRIGGER trg_validar_un_valor_por_atributo
  BEFORE INSERT OR UPDATE
                     ON variantes_valores_atributo
                     FOR EACH ROW
                     EXECUTE FUNCTION validar_un_valor_por_atributo();


-- ============================================================
-- 6. FUNCION:
-- Validar que el atributo utilizado por una variante pertenezca
-- al mismo comercio del producto.
-- ============================================================

CREATE OR REPLACE FUNCTION validar_atributo_variante_comercio()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
comercio_producto BIGINT;
    comercio_atributo BIGINT;
BEGIN

SELECT c.comercio_id
INTO comercio_producto
FROM variantes_producto vp
       JOIN productos p
            ON p.id = vp.producto_id
       JOIN categorias c
            ON c.id = p.categoria_id
WHERE vp.id = NEW.variante_producto_id;

SELECT a.comercio_id
INTO comercio_atributo
FROM valores_atributo va
       JOIN atributos a
            ON a.id = va.atributo_id
WHERE va.id = NEW.valor_atributo_id;

IF comercio_producto IS DISTINCT FROM comercio_atributo THEN
        RAISE EXCEPTION
            'El atributo no pertenece al mismo comercio del producto';
END IF;

RETURN NEW;
END;
$$;


CREATE TRIGGER trg_validar_atributo_variante_comercio
  BEFORE INSERT OR UPDATE
                     ON variantes_valores_atributo
                     FOR EACH ROW
                     EXECUTE FUNCTION validar_atributo_variante_comercio();
