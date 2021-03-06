USE [ComparativoRM]
GO
/****** Object:  StoredProcedure [dbo].[AF0069_ComparativoMueblesDetalle]    Script Date: 10/26/2013 16:19:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[AF0069_ComparativoMueblesDetalle]
as
-- =============================================
-- Autor: Antonio Acosta Murillo
-- Fecha: 11 octubre 2013
-- Descripción general: genera comparativo de ventas muebles detallado de carteras contra inventario muebles del mes 
-- =============================================
begin

-------------------------------- Ventas muebles detallado por factura o nota -----------------------------------
declare @hora as nvarchar(9)
set @hora =  ((select CONVERT(nvarchar(40),getdate(),108)))

--Insertar en la Bitacora del Comparativo de RM
set @hora =  (select CONVERT(nvarchar(40),getdate(),108))
insert into dbo.BitacoraCOMPARATIVOM
values (@hora,'Inicia el procedimiento AF0069_ComparativoMueblesDetalle (INFORME Detelle Muebles)')
 
-- Se Agarran Las Tiendas A Detalle Que Tuvieron Diferencia
if exists(select * from sysobjects where name = 'tmpventasmueblescarterasdetallemes') drop table tmpventasmueblescarterasdetallemes
select *
into dbo.TmpVentasMueblesCarterasDetalleMes
from tmpventasmueblescarterasmes a
where exists (select * from tmpventascomparacionmueblesfinal where numerotienda = a.numerotienda and fechamovimiento = a.fechamovimiento) 

update TmpVentasMueblesCarterasDetalleMes
set Ventas = 0
where exists(select * from TmpVentasComparacionMueblesFinal where NumeroTienda = TmpVentasMueblesCarterasDetalleMes.NumeroTienda and FechaMovimiento = TmpVentasMueblesCarterasDetalleMes.FechaMovimiento and DifVentas = 0)

update TmpVentasMueblesCarterasDetalleMes
set TiempoAire = 0
where exists(select * from TmpVentasComparacionMueblesFinal where NumeroTienda = TmpVentasMueblesCarterasDetalleMes.NumeroTienda and FechaMovimiento = TmpVentasMueblesCarterasDetalleMes.FechaMovimiento and DifTA = 0)

update TmpVentasMueblesCarterasDetalleMes
set Devoluciones = 0
where exists(select * from TmpVentasComparacionMueblesFinal where NumeroTienda = TmpVentasMueblesCarterasDetalleMes.NumeroTienda and FechaMovimiento = TmpVentasMueblesCarterasDetalleMes.FechaMovimiento and DifDevoluciones = 0)

--Insertar en la Bitacora del Comparativo de RM
set @hora =  (select CONVERT(nvarchar(40),getdate(),108))
insert into dbo.BitacoraCOMPARATIVOM
values (@hora,'Se Agarran Las Tiendas A Detalle Que Tuvieron Diferencia')

-- Ventas Inv. MueblesDetalle (TmpVentasInvMueblesDetalleMes)
-- Se Deja La Misma Estructura Que Las Ventas Muebles Carteras Detalle
If Exists(Select * From SysObjects Where Name = 'TmpVentasInvMueblesDetalleMes2') Drop Table TmpVentasInvMueblesDetalleMes2
Select Tienda,Fecha,Folio,
Ventas = isnull((select sum(TotalFacturado) from TmpVentasInvMueblesDetalleMes where TipoMov = 'VT' and Tienda = a.Tienda and Fecha = a.Fecha and Folio = a.Folio),0),
TiempoAire = isnull((select sum(TotalFacturado) from TmpVentasInvMueblesDetalleMes where TipoMov = 'TA' and Tienda = a.Tienda and Fecha = a.Fecha and Folio = a.Folio),0),
Devoluciones = isnull((select sum(TotalFacturado) from TmpVentasInvMueblesDetalleMes where TipoMov = 'DV' and Tienda = a.Tienda and Fecha = a.Fecha and Folio = a.Folio),0)
into dbo.TmpVentasInvMueblesDetalleMes2
from TmpVentasInvMueblesDetalleMes a
where exists (select * from tmpventascomparacionmueblesfinal where numerotienda = a.tienda and fechamovimiento = a.fecha)

--Insertar en la Bitacora del Comparativo de RM
set @hora =  (select CONVERT(nvarchar(40),getdate(),108))
insert into dbo.BitacoraCOMPARATIVOM
values (@hora,'Ventas Inv. MueblesDetalle (TmpVentasInvMueblesDetalleMes)')

--Insertar en la Bitacora del Comparativo de RM
set @hora =  (select CONVERT(nvarchar(40),getdate(),108))
insert into dbo.BitacoraCOMPARATIVOM
values (@hora,'Se Deja La Misma Estructura Que Las Ventas Muebles Carteras Detalle')

-- Se Forma Tabla Con Las Tiendas,Dias Y Facturas De Las 2 Tablas
If Exists(Select * From SysObjects Where Name = 'TmpVentasComparacionMueblesDetalleMes') Drop Table TmpVentasComparacionMueblesDetalleMes
Select Distinct NumeroTienda,FechaMovimiento,FacturaoNota,VentaInvMueblesDetalle = cast (0 as bigint),TAInvMueblesDetalle = cast (0 as bigint),DevInvMueblesDetalle = cast (0 as bigint),VentaMueblesDetalle = cast (0 as bigint),TAMueblesDetalle = cast (0 as bigint),DevMueblesDetalle = cast (0 as bigint)
Into dbo.TmpVentasComparacionMueblesDetalleMes
From TmpVentasMueblesCarterasDetalleMes
Union all
Select Distinct Tienda,Fecha,Folio,VentaInvMueblesDetalle = cast (0 as bigint),TAInvMueblesDetalle = cast (0 as bigint),DevInvMueblesDetalle = cast (0 as bigint),VentaMueblesDetalle = cast (0 as bigint),TAMueblesDetalle = cast (0 as bigint),DevMueblesDetalle = cast (0 as bigint)
From TmpVentasInvMueblesDetalleMes2

--Insertar en la Bitacora del Comparativo de RM
set @hora =  (select CONVERT(nvarchar(40),getdate(),108))
insert into dbo.BitacoraCOMPARATIVOM
values (@hora,'Se Forma Tabla Con Las Tiendas,Dias Y Facturas De Las 2 Tablas')

-- Se Quedan Las Tiendas Y Dias Sin Repetir
If Exists(Select * From SysObjects Where Name = 'TmpVentasComparacionMueblesDetalleMes2') Drop Table TmpVentasComparacionMueblesDetalleMes2
Select distinct * Into dbo.TmpVentasComparacionMueblesDetalleMes2 From TmpVentasComparacionMueblesDetalleMes

--Insertar en la Bitacora del Comparativo de RM
set @hora =  (select CONVERT(nvarchar(40),getdate(),108))
insert into dbo.BitacoraCOMPARATIVOM
values (@hora,'Se Quedan Las Tiendas Y Dias Sin Repetir')

-- Se Actualiza La Venta,Ta y Dev De Inv.Muebles
Update TmpVentasComparacionMueblesDetalleMes2
Set VentaInvMueblesDetalle = a. Ventas,
	 TAInvMueblesDetalle = a.TiempoAire,
	 DevInvMueblesDetalle = a.Devoluciones
From TmpVentasInvMueblesDetalleMes2 a 
Where TmpVentasComparacionMueblesDetalleMes2.Numerotienda = a.Tienda and 
		 TmpVentasComparacionMueblesDetalleMes2.FechaMovimiento = a.Fecha and 
		  TmpVentasComparacionMueblesDetalleMes2.FacturaoNota = a.Folio
		  
--Insertar en la Bitacora del Comparativo de RM
set @hora =  (select CONVERT(nvarchar(40),getdate(),108))
insert into dbo.BitacoraCOMPARATIVOM
values (@hora,'Se Actualiza La Venta,Ta y Dev De Inv.Muebles')

-- Se Actualiza La Venta,Ta y Dev De Carteras
Update TmpVentasComparacionMueblesDetalleMes2
Set VentaMueblesDetalle = a. Ventas,
	 TAMueblesDetalle = a.TiempoAire,
	 DevMueblesDetalle = a.Devoluciones
From TmpVentasMueblesCarterasDetalleMes a 
Where TmpVentasComparacionMueblesDetalleMes2.Numerotienda = a.NumeroTienda and 
		 TmpVentasComparacionMueblesDetalleMes2.FechaMovimiento = a.FechaMovimiento and 
		  TmpVentasComparacionMueblesDetalleMes2.FacturaoNota = a.FacturaoNota
		  
--Insertar en la Bitacora del Comparativo de RM
set @hora =  (select CONVERT(nvarchar(40),getdate(),108))
insert into dbo.BitacoraCOMPARATIVOM
values (@hora,' Se Actualiza La Venta,Ta y Dev De Carteras')
		  
-- Se Sacan Las Diferencias Por Cada Concepto
If Exists(Select * From SysObjects Where Name = 'TmpVentasComparacionMueblesDetalleMes3') Drop Table TmpVentasComparacionMueblesDetalleMes3
Select *,DifVentas = VentaMueblesDetalle-VentaInvMueblesDetalle, DifTA = TAMueblesDetalle-TAInvMueblesDetalle, DifDevoluciones = DevMueblesDetalle-DevInvMueblesDetalle
Into dbo.TmpVentasComparacionMueblesDetalleMes3
From TmpVentasComparacionMueblesDetalleMes2

--Insertar en la Bitacora del Comparativo de RM
set @hora =  (select CONVERT(nvarchar(40),getdate(),108))
insert into dbo.BitacoraCOMPARATIVOM
values (@hora,'Se Sacan Las Diferencias Por Cada Concepto')

-- Tabla Para Informe de ventas de Muebles recibidas y procesadas
If Exists(Select * From SysObjects Where Name = 'TmpVentasComparacionMueblesDetalleFinal') Drop Table TmpVentasComparacionMueblesDetalleFinal
Select *, DifTotal = DifVentas + DifTA + DifDevoluciones
Into dbo.TmpVentasComparacionMueblesDetalleFinal
From TmpVentasComparacionMueblesDetalleMes3
Order By FechaMovimiento,NumeroTienda,FacturaoNota

--Insertar en la Bitacora del Comparativo de RM
set @hora =  (select CONVERT(nvarchar(40),getdate(),108))
insert into dbo.BitacoraCOMPARATIVOM
values (@hora,'Tabla Para Informe de ventas de Muebles recibidas y procesadas')

-- Elimino Donde No Hay Diferencia
Delete from TmpVentasComparacionMueblesDetalleFinal where diftotal = 0

--Insertar en la Bitacora del Comparativo de RM
set @hora =  (select CONVERT(nvarchar(40),getdate(),108))
insert into dbo.BitacoraCOMPARATIVOM
values (@hora,'Elimino Donde No Hay Diferencia')

--Insertar en la Bitacora del Comparativo de RM
set @hora =  (select CONVERT(nvarchar(40),getdate(),108))
insert into dbo.BitacoraCOMPARATIVOM
values (@hora,'Fin del procedimiento AF_0069ComparativoMueblesDetalle')

/*===============================================================================================*/  
/*                                  limpiando temporales                                         */  
/*===============================================================================================*/  
if exists(select * from sysobjects where name = 'tmptransaccionesmes') drop table tmptransaccionesmes
if exists(select * from sysobjects where name = 'tmpventasmueblescarterasmes2') drop table tmpventasmueblescarterasmes2
if exists(select * from sysobjects where name = 'tmpventasinvmueblesmes2') drop table tmpventasinvmueblesmes2
if exists(select * from sysobjects where name = 'tmpventascomparacionmueblesmes') drop table tmpventascomparacionmueblesmes
if exists(select * from sysobjects where name = 'tmpventascomparacionmueblesmes2') drop table tmpventascomparacionmueblesmes2
if exists(select * from sysobjects where name = 'tmpventascomparacionmueblesmes3') drop table tmpventascomparacionmueblesmes3
if exists(select * from sysobjects where name = 'tmpventascomparacionmueblesmes4') drop table tmpventascomparacionmueblesmes4
if exists (select * from sysobjects where name = 'TmpVentasInvMuebles') drop table TmpVentasInvMuebles
if exists (select * from sysobjects where name = 'queryinvmueblesmes') drop table queryinvmueblesmes
if exists (select * from sysobjects where name = 'TmpVentasInvMuebles') drop table 
dbo.TmpVentasInvMuebles
if exists (select * from sysobjects where name = 'TmpVentasInvMueblesDetalleMes') drop table 
dbo.TmpVentasInvMueblesDetalleMes
if exists (select * from sysobjects where name = 'tmpventascomparacionmueblesfinal') drop table tmpventascomparacionmueblesfinal
if exists(select * from sysobjects where name = 'tmpventasmueblescarterasmes') drop table tmpventasmueblescarterasmes

end
GO
