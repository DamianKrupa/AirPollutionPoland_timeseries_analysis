--===================Let's see whether imported tables work================================================= 
go
declare @szukacz as numeric(7,3)
set @szukacz = 530

select * from [dbo].[stacje_pomiarowe]
--where stationName = 'Duszniki-Zdrój'
order by stationName

select * from [dbo].[stanowiska_pomiarowe]
--where stationId = @szukacz

select * from [dbo].[dane pomiarowe]
--where Id_para = 3575
go
--================Let's see whether coordinates work properly (check results in spatial results)=================================================
--drop table [GIOŒ_GEOGRAFIA_stacje_pomiarowe]
select * into [GIOŒ_GEOGRAFIA_stacje_pomiarowe] from dbo.[stacje_pomiarowe]
alter table [GIOŒ_GEOGRAFIA_stacje_pomiarowe]
add
Geography_cor AS geography::
		STGeomFromText('POINT('+CONVERT(VARCHAR(40),gegrLon)+' '+CONVERT(VARCHAR(40),gegrLat)+')',4326 )

select * from [GIOŒ_GEOGRAFIA_stacje_pomiarowe]
go
--===================Let's create procedure we export to Tableau==============================================================
--This procedure is a temporary table which shows the relation between all 3 downladed tables. We export its result to Tableu
--in order to present data in atractive way.

--Because work on procedure required lot of patches, the statement below turned out to be much more than usefull.
if object_ID('LastValue','P') is not null
drop proc LastValue
go

-- Convertion and cast some data to make data more valuable and efficient.
create procedure LastValue (@Condition as nvarchar(50), @Condition2 as nvarchar(50)) as
begin

	select
	StacjeP.gegrLat as Latitude, 
	StacjeP.gegrLon as Longitude,
	cast(StacjeP.stationName as char(50)) as StationName,
	cast(StacjeP.city_commune_provinceName as varchar(50)) as Voivodeship,
	cast(DP.date as datetime) as Time,
	format(cast(substring(DP.date,11,9) as time), N'hh\:mm') as Hour_, 
	datepart(day, DP.date) as Day_,
	cast(StanoP.param_paramFormula as char(5)) as PhysicochemicalFormula, 
	cast(DP.value as decimal(8,4)) as [Values],

--We used the case statement to create new columns. Condtions for each parameters you can find here:
--http://powietrze.gios.gov.pl/pjp/current


			case when StanoP.param_paramFormula in ('NO2', 'O3', 'C6H6', 
													'PM10', 'PM2.5', 'CO', 'SO2') then '[µg/m3]'																		
			end

	as Unit,
			
			case when StanoP.param_paramFormula = 'NO2' and DP.value <= 40 then 'Very good'
				 when StanoP.param_paramFormula = 'NO2' and	DP.value > 40 and  DP.value <=100 then 'Good'
				 when StanoP.param_paramFormula = 'NO2' and	DP.value > 100 and DP.value <= 150 then 'Moderate'
				 when StanoP.param_paramFormula = 'NO2' and	DP.value > 150 and DP.value <= 200 then 'Sufficient'
				 when StanoP.param_paramFormula = 'NO2' and	DP.value > 200 and DP.value <= 400 then 'Bad'
				 when StanoP.param_paramFormula = 'NO2' and	DP.value > 400 then 'Very bad'
														
				 when StanoP.param_paramFormula = 'O3' and	DP.value <= 70  then 'Very good'
				 when StanoP.param_paramFormula = 'O3' and	DP.value > 70 and  DP.value <= 120 then 'Good'
				 when StanoP.param_paramFormula = 'O3' and	DP.value > 120 and DP.value <= 150 then 'Moderate'
				 when StanoP.param_paramFormula = 'O3' and	DP.value > 150 and DP.value <= 180 then 'Sufficient'
				 when StanoP.param_paramFormula = 'O3' and	DP.value > 180 and DP.value <= 240 then 'Bad'
				 when StanoP.param_paramFormula = 'O3' and	DP.value > 240 then 'Very bad'

				 when StanoP.param_paramFormula = 'C6H6' and	DP.value <= 6  then 'Very good'
				 when StanoP.param_paramFormula = 'C6H6' and	DP.value > 6 and  DP.value <=11 then 'Good'
				 when StanoP.param_paramFormula = 'C6H6' and	DP.value > 11 and DP.value <= 16 then 'Moderate'
				 when StanoP.param_paramFormula = 'C6H6' and	DP.value > 16 and DP.value <= 21 then 'Sufficient'
				 when StanoP.param_paramFormula = 'C6H6' and	DP.value > 21 and DP.value <= 51 then 'Bad'
				 when StanoP.param_paramFormula = 'C6H6' and	DP.value > 51 then 'Very bad'

				 when StanoP.param_paramFormula = 'CO' and	DP.value/1000 <= 3  then 'Very good'
				 when StanoP.param_paramFormula = 'CO' and	DP.value/1000 > 3 and  DP.value/1000 <=7 then 'Good'
				 when StanoP.param_paramFormula = 'CO' and	DP.value/1000 > 7 and DP.value/1000 <= 11 then 'Moderate'
				 when StanoP.param_paramFormula = 'CO' and	DP.value/1000 > 11 and DP.value/1000 <= 15 then 'Sufficient'
				 when StanoP.param_paramFormula = 'CO' and	DP.value/1000 > 15 and DP.value/1000 <= 21 then 'Bad'
				 when StanoP.param_paramFormula = 'CO' and	DP.value/1000 > 21 then 'Very bad'

				 when StanoP.param_paramFormula = 'PM10' and	DP.value <= 20  then 'Very good'
				 when StanoP.param_paramFormula = 'PM10' and	DP.value > 20 and  DP.value <=50 then 'Good'
				 when StanoP.param_paramFormula = 'PM10' and	DP.value > 50 and DP.value <= 80 then 'Moderate'
				 when StanoP.param_paramFormula = 'PM10' and	DP.value > 80 and DP.value <= 110 then 'Sufficient'
				 when StanoP.param_paramFormula = 'PM10' and	DP.value > 110 and DP.value <= 150 then 'Bad'
				 when StanoP.param_paramFormula = 'PM10' and	DP.value > 150 then 'Very bad'

				 when StanoP.param_paramFormula = 'PM2.5' and	DP.value <= 13  then 'Very good'
				 when StanoP.param_paramFormula = 'PM2.5' and	DP.value > 13 and  DP.value <=35 then 'Good'
				 when StanoP.param_paramFormula = 'PM2.5' and	DP.value > 35 and DP.value <= 55 then 'Moderate'
				 when StanoP.param_paramFormula = 'PM2.5' and	DP.value > 55 and DP.value <= 75 then 'Sufficient'
				 when StanoP.param_paramFormula = 'PM2.5' and	DP.value > 75 and DP.value <= 110 then 'Bad'
				 when StanoP.param_paramFormula = 'PM2.5' and	DP.value > 110 then 'Very bad'

				 when StanoP.param_paramFormula = 'SO2' and	DP.value <= 50  then 'Very good'
				 when StanoP.param_paramFormula = 'SO2' and	DP.value > 50 and  DP.value <=100 then 'Good'
				 when StanoP.param_paramFormula = 'SO2' and	DP.value > 100 and DP.value <= 200 then 'Moderate'
				 when StanoP.param_paramFormula = 'SO2' and	DP.value > 200 and DP.value <= 350 then 'Sufficient'
				 when StanoP.param_paramFormula = 'SO2' and	DP.value > 350 and DP.value <= 500 then 'Bad'
				 when StanoP.param_paramFormula = 'SO2' and	DP.value > 500 then 'Very bad'
																		   else 'No data'
			end
	as IndexQuality

	from [stacje_pomiarowe] as StacjeP
	left join
	[dbo].[stanowiska_pomiarowe] as StanoP
	on StanoP.stationId = StacjeP.id
	left join [Dane pomiarowe] as DP
	on DP.Id_para = StanoP.id
	where DP.value is not null 
	and StacjeP.city_name like @Condition
	and StanoP.param_paramFormula like @Condition2
	order by DP.date

end
go

execute LastValue '%', '%'


http://powietrze.gios.gov.pl/pjp/current/station_details/chart/485
--Otwock_Brzozowa station - yearly forecast of NO2 emission 
select ds,yhat from [dbo].[forecast_2020_NO2_stat]
where YEAR(ds) = 2020 and MONTH(ds) = 10 and DAY(ds) = 12
select * from forecast_2020_NO2_stat



