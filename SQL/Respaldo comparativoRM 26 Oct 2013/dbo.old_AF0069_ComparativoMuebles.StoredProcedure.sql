USE [ComparativoRM]
GO
/****** Object:  StoredProcedure [dbo].[old_AF0069_ComparativoMuebles]    Script Date: 10/26/2013 16:19:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[old_AF0069_ComparativoMuebles]
(@fechainicio char(10),@fechafin char(10))
as
-- =============================================
-- autor: Antonio Acosta Murillo
-- fecha: 03 octubre 2013
-- descripción general: genera comparativo de ventas muebles de carteras contra inventario muebles del mes 
-- =============================================
begin

-------------------------------- ventas muebles totales ----------------------------------- 
declare @sentencia as varchar(8000)  
declare @ano as char(4)
declare @hora as nvarchar(9)
set @ano = (select year(fechacorte) from controltiendas.dbo.ctlmaestrafechas)
set @hora =  ((select CONVERT(nvarchar(40),getdate(),108)))

--Se crea la tabla "Bitacora" para almacenar la hora y la descripción de cada instrucción del procedimiento
if exists (select * from sysobjects where name = 'BitacoraCOMPARATIVOM') drop table BitacoraCOMPARATIVOM
create table BitacoraCOMPARATIVOM
(
	hora nvarchar(9),
	descripcion nvarchar(100)
)

--Insertar en la Bitacora del Comparativo de RM
set @hora =  (select CONVERT(nvarchar(40),getdate(),108))
insert into dbo.BitacoraCOMPARATIVOM
values (@hora,'Inicia el procedimiento AF0069_ComparativoMuebles (INFORME GENERAL Muebles)')

if exists(select * from sysobjects where name = 'tmptransaccionesmes') drop table tmptransaccionesmes
set @sentencia =  
'select clavemovimiento,tipomovimiento,numerotienda,fechamovimiento,facturaonota,importe,interes
into dbo.tmptransaccionesmes
from cargas' + @ano +'.dbo.ctlcargatransacciones a
where ((ascii(clavemovimiento) = 77 and tipomovimiento in (''1'',''2'',''5'',''6'',''9'')) or
		 (ascii(clavemovimiento) = 65 and tipomovimiento in (''3'',''4'',''5'',''6'',''7'',''8'')) or
		 (ascii(clavemovimiento) = 65 and ascii(tipomovimiento) = 65) or
		 (ascii(clavemovimiento) = 65 and ascii(tipomovimiento) = 66) or 
		 (ascii(clavemovimiento) = 65 and ascii(tipomovimiento) = 67) or
		 (ascii(clavemovimiento) = 65 and ascii(tipomovimiento) = 68)) and  fechamovimiento between  ''' + @fechainicio + ''' and ''' + @fechafin  + ''''
exec (@sentencia)

--Insertar en la Bitacora del Comparativo de M
set @hora =  (select CONVERT(nvarchar(40),getdate(),108))
insert into dbo.BitacoraCOMPARATIVOM
values (@hora,'Termina de traer la informacion de la tabla ctlCargaTransacciones')

-- ventas muebles carteras del mes
if exists(select * from sysobjects where name = 'tmpventasmueblescarterasmes') drop table tmpventasmueblescarterasmes
select a.numerotienda,a.fechamovimiento,a.facturaonota,
	ventas = (select isnull(sum(isnull(importe,0)+isnull(interes,0)),0) from tmptransaccionesmes where clavemovimiento + tipomovimiento in ('M1','M2','M5','M6') and numerotienda = a.numerotienda and fechamovimiento = a.fechamovimiento and facturaonota=a.facturaonota),
	tiempoaire = (select isnull(sum(isnull(importe,0)+isnull(interes,0)),0) from tmptransaccionesmes where clavemovimiento + tipomovimiento in ('A3','A4','A5','A6','A7','A8','AA','AB','AC', 'AD') and NumeroTienda = a.NumeroTienda and FechaMovimiento = a.FechaMovimiento and FacturaoNota=a.FacturaoNota),
	Devoluciones = (select isnull(sum(isnull(Importe,0)+isnull(Interes,0)),0) from tmptransaccionesMes where clavemovimiento + tipomovimiento in ('M9') and numerotienda = a.numerotienda and fechamovimiento = a.fechamovimiento and facturaonota=a.facturaonota)
into dbo.tmpventasmueblescarterasmes
from tmptransaccionesmes a
group by a.numerotienda,a.fechamovimiento,a.facturaonota

--Insertar en la Bitacora del Comparativo de M
set @hora =  (select CONVERT(nvarchar(40),getdate(),108))
insert into dbo.BitacoraCOMPARATIVOM
values (@hora,'Ventas muebles cartaras del mes')

-- se deja al nivel tienda - dia
if exists(select * from sysobjects where name = 'tmpventasmueblescarterasmes2') drop table tmpventasmueblescarterasmes2
select numerotienda,fechamovimiento,sum(cast(ventas as bigint)) as  ventas,sum(cast(tiempoaire as bigint)) as  tiempoaire,sum(cast(devoluciones as bigint)) as  devoluciones
into dbo.tmpventasmueblescarterasmes2
from tmpventasmueblescarterasmes
group by numerotienda,fechamovimiento

--Insertar en la Bitacora del Comparativo de M
set @hora =  (select CONVERT(nvarchar(40),getdate(),108))
insert into dbo.BitacoraCOMPARATIVOM
values (@hora,'Se deja al nivel tienda-dia')

-- ventas inv. muebles (tmpventasinvmuebles) del mes
if exists(select * from sysobjects where name = 'tmpventasinvmueblesmes2') drop table tmpventasinvmueblesmes2
select tienda,fecha,venta,tiempoaire,devoluciones
into dbo.tmpventasinvmueblesmes2
from tmpventasinvmuebles a
where exists(select * from tmpventasmueblescarterasmes2 where numerotienda = a.tienda and fechamovimiento = a.fecha)

--Insertar en la Bitacora del Comparativo de M
set @hora =  (select CONVERT(nvarchar(40),getdate(),108))
insert into dbo.BitacoraCOMPARATIVOM
values (@hora,'Ventas inv. muebles (tmpVentasInvMuebles) del mes')

-- dejo la mista tienda/fecha de lo trabajado en carteras
delete from tmpventasinvmueblesmes2
where not exists (select * from tmpventasmueblescarterasmes2 where numerotienda = tmpventasinvmueblesmes2.tienda and fechamovimiento = tmpventasinvmueblesmes2.fecha)

--Insertar en la Bitacora del Comparativo de M
set @hora =  (select CONVERT(nvarchar(40),getdate(),108))
insert into dbo.BitacoraCOMPARATIVOM
values (@hora,'Se deja las mismas tiendas/fechas que se trabajaron en Carteras')

-- se forma tabla con las tiendas y dias de las 2 tablas
if exists(select * from sysobjects where name = 'tmpventascomparacionmueblesmes') drop table tmpventascomparacionmueblesmes
select distinct numerotienda,fechamovimiento into dbo.tmpventascomparacionmueblesmes from tmpventasmueblescarterasmes2
union all
select distinct tienda,fecha from tmpventasinvmueblesmes2

-- se quedan las tiendas y dias sin repetir
if exists(select * from sysobjects where name = 'tmpventascomparacionmueblesmes2') drop table tmpventascomparacionmueblesmes2
select distinct * into dbo.tmpventascomparacionmueblesmes2 from tmpventascomparacionmueblesmes

--Insertar en la Bitacora del Comparativo de M
set @hora =  (select CONVERT(nvarchar(40),getdate(),108))
insert into dbo.BitacoraCOMPARATIVOM
values (@hora,'Se quedan las tiendas y dias sin trabajar')

-- se tienen las ventas,tiempoaire y devoluciones a nivel tienda dia
if exists(select * from sysobjects where name = 'tmpventascomparacionmueblesmes3') drop table tmpventascomparacionmueblesmes3
select a.*,isnull(b.venta,0) ventasm,isnull(b.tiempoaire,0) tiempoairem,isnull(b.devoluciones,0) devolucionesm,isnull(c.ventas,0) ventasc,isnull(c.tiempoaire,0) tiempoairec,isnull(c.devoluciones,0) devolucionesc
into dbo.tmpventascomparacionmueblesmes3
from tmpventascomparacionmueblesmes2 a 
	left join tmpventasinvmueblesmes2 b 
		on (a.numerotienda = b.tienda and a.fechamovimiento = b.fecha) 
	left join tmpventasmueblescarterasmes2 c 
		on (a.numerotienda = c.numerotienda and a.fechamovimiento = c.fechamovimiento)
order by a.fechamovimiento,a.numerotienda

--Insertar en la Bitacora del Comparativo de M
set @hora =  (select CONVERT(nvarchar(40),getdate(),108))
insert into dbo.BitacoraCOMPARATIVOM
values (@hora,'Se tiene las ventas, tiempo aire y devoluciones a nivel tienda-dia')

-- se sacan las diferencias por cada concepto
if exists(select * from sysobjects where name = 'tmpventascomparacionmueblesmes4') drop table tmpventascomparacionmueblesmes4
select *,difventas = ventasc-ventasm, difta = tiempoairec-tiempoairem, difdevoluciones = devolucionesc-devolucionesm
into dbo.tmpventascomparacionmueblesmes4
from tmpventascomparacionmueblesmes3

--Insertar en la Bitacora del Comparativo de M
set @hora =  (select CONVERT(nvarchar(40),getdate(),108))
insert into dbo.BitacoraCOMPARATIVOM
values (@hora,'Se calculan las diferencias por cada concepto')

-- tabla para informe de ventas de muebles recibidas y procesadas
if exists(select * from sysobjects where name = 'tmpventascomparacionmueblesfinal') drop table tmpventascomparacionmueblesfinal
select *, diftotal = difventas + difta + difdevoluciones
into dbo.tmpventascomparacionmueblesfinal
from tmpventascomparacionmueblesmes4

-- elimino donde no hay diferencia
delete from tmpventascomparacionmueblesfinal where (diftotal = 0) or (ventasm = 0 and tiempoairem = 0 and devolucionesm = 0) or (ventasc = 0 and tiempoairec = 0 and devolucionesc = 0)

--Insertar en la Bitacora del Comparativo de M
set @hora =  (select CONVERT(nvarchar(40),getdate(),108))
insert into dbo.BitacoraCOMPARATIVOM
values (@hora,'Se elimina donde no hay diferencia')

-- dejo formada la tabla para traerme el detalle de inv muebles
if exists(select * from sysobjects where name = 'queryinvmueblesmes') drop table queryinvmueblesmes
select   flagventa = case when difventas <> 0 then 1 else 0 end,
		   flagta = case when difta <> 0 then 1 else 0 end, 
		   flagdev = case when difdevoluciones <> 0 then 1 else 0 end,
		   execproc = 'exec proc_detalletdascarteras ' + char(39) + cast(year(fechamovimiento) as char(4)) + '-' + cast(month(fechamovimiento) as char(2)) + '-' + cast(day(fechamovimiento) as char(2)) + char(39) + ',' + cast(numerotienda as varchar(5))
into dbo.queryinvmueblesmes
from tmpventascomparacionmueblesfinal
order by FechaMovimiento, NumeroTienda

--Insertar en la Bitacora del Comparativo de M
set @hora =  (select CONVERT(nvarchar(40),getdate(),108))
insert into dbo.BitacoraCOMPARATIVOM
values (@hora,'Se crea una tabla para taer el detalle de inv. muebles')

-- dejo formada la tabla para traerme el detalle de inv muebles final
if exists (select * from sysobjects where name = 'QueryInvMueblesMes_Final') drop table QueryInvMueblesMes_Final
create table QueryInvMueblesMes_Final
(execproc varchar(51))

-- se seleccionan las ventas con el flagventas
insert into QueryInvMueblesMes_Final
select execproc+',1' 
from queryinvmueblesmes
where flagventa = 1

-- se seleccionan las ventas con el flagta
insert into QueryInvMueblesMes_Final
select execproc+',2' 
from queryinvmueblesmes
where flagta = 1

-- se seleccionan las ventas con el flagdev
insert into QueryInvMueblesMes_Final
select execproc+',3' 
from queryinvmueblesmes
where flagdev = 1

--Insertar en la Bitacora del Comparativo de M
set @hora =  (select CONVERT(nvarchar(40),getdate(),108))
insert into dbo.BitacoraCOMPARATIVOM
values (@hora,'Se crea la tabla Final para traer el detalle de inv muebles (QueryInvMueblesMes_Final)')

--Insertar en la Bitacora del Comparativo de M
set @hora =  (select CONVERT(nvarchar(40),getdate(),108))
insert into dbo.BitacoraCOMPARATIVOM
values (@hora,'Fin del procedimiento AF0069_ComparativoMuebles')

/*===============================================================================================*/  
/*                                  limpiando temporales                                         */  
/*===============================================================================================*/  
--if exists(select * from sysobjects where name = 'tmptransaccionesmes') drop table tmptransaccionesmes
--if exists(select * from sysobjects where name = 'tmpventasmueblescarterasmes') drop table tmpventasmueblescarterasmes
if exists(select * from sysobjects where name = 'tmpventasmueblescarterasmes2') drop table tmpventasmueblescarterasmes2
if exists(select * from sysobjects where name = 'tmpventasinvmueblesmes2') drop table tmpventasinvmueblesmes2
if exists(select * from sysobjects where name = 'tmpventascomparacionmueblesmes') drop table tmpventascomparacionmueblesmes
if exists(select * from sysobjects where name = 'tmpventascomparacionmueblesmes2') drop table tmpventascomparacionmueblesmes2
if exists(select * from sysobjects where name = 'tmpventascomparacionmueblesmes3') drop table tmpventascomparacionmueblesmes3
if exists(select * from sysobjects where name = 'tmpventascomparacionmueblesmes4') drop table tmpventascomparacionmueblesmes4

--Insertar en la Bitacora del Comparativo de M
set @hora =  (select CONVERT(nvarchar(40),getdate(),108))
insert into dbo.BitacoraCOMPARATIVOM
values (@hora,'Se eliminan las tablas temporales')

end
GO
