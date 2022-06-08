USE AdventureWorks2012;
DROP PROCEDURE IF EXISTS dbo.Pro_Cohort
GO
CREATE PROCEDURE Pro_Cohort (@s_date DATE = '2013-01-01',@peri INT = 12, @period NVARCHAR(20)='Month')
AS
BEGIN
DECLARE @sqlToExecute NVARCHAR(MAX);
	SET @sqlToExecute = N'
	DECLARE @maxdate DATE = (SELECT MAX(OrderDate) FROM Sales.SalesOrderHeader);
	DECLARE @columns NVARCHAR(MAX) = '''';
	if OBJECT_ID(N''dbo.cohort_size'', N''U'') is not null drop table dbo.cohort_size
	CREATE TABLE cohort_size(start_date date, end_date date, N_th int, Name_th nvarchar(20), count_ int);
	WITH first_date AS (
	SELECT
		CustomerID, MIN(OrderDate) first_date
	FROM Sales.SalesOrderHeader
	GROUP BY CustomerID
	),
		hie_data AS
	(
		SELECT @s_date AS start_date,
		DATEADD(DAY,-1,DATEADD('+@period+',1,@s_date)) end_date
		UNION ALL 
		SELECT
			DATEADD('+@period+',1,cte.start_date) AS start_date,
			DATEADD(DAY,-1,DATEADD('+@period+',2,cte.start_date)) end_date
		FROM hie_data cte
		WHERE cte.end_date< @maxdate
	),
		data_cus AS (
	SELECT
		cte.start_date, cte.end_date, h.OrderDate, h.CustomerID
	FROM hie_data cte INNER JOIN Sales.SalesOrderHeader h
	ON h.OrderDate>= cte.start_date AND h.OrderDate<= cte.end_date)

	INSERT INTO cohort_size
	SELECT 
		tb2.start_date, tb2.end_date,
		DATEDIFF('+@period+',tb2.start_date,tb3.start_date) N_th,
		@period+ '' ''+ CONVERT(NVARCHAR,DATEDIFF('+@period+',tb2.start_date,tb3.start_date)) Name_th,
		COUNT(DISTINCT tb2.CustomerID) AS count_
	FROM first_date tb1 INNER JOIN data_cus tb2 
	ON tb2.CustomerID = tb1.CustomerID AND tb1.first_date >= tb2.start_date AND tb1.first_date<= tb2.end_date
	INNER JOIN data_cus tb3
	ON tb2.start_date<= tb3.start_date AND DATEADD('+@period+',@peri,tb2.start_date)>= tb3.start_date AND tb2.CustomerID = tb3.CustomerID
	GROUP BY tb2.start_date, tb2.end_date,
		DATEDIFF('+@period+',tb2.start_date,tb3.start_date)

	IF OBJECT_ID(N''dbo.cohort_per'', N''U'') is not null drop table dbo.cohort_per
	CREATE TABLE cohort_per(start_date date, end_date date, N_th int, Name_th nvarchar(20), per float);
	INSERT INTO cohort_per
	SELECT
		start_date, end_date, N_th, Name_th,
		ROUND(CONVERT(FLOAT, count_)/FIRST_VALUE(count_) OVER (PARTITION BY start_date ORDER BY N_th)*100,1) per
	FROM cohort_size

	SELECT @columns += QUOTENAME(Name_th)+ '','' 
	FROM cohort_size
	GROUP BY Name_th, N_th
	ORDER BY N_th, Name_th;
	
	SET @columns = LEFT(@columns, len(@columns)-1) 
	DECLARE @sql1 NVARCHAR(max)='''',
		@sql2 NVARCHAR(max)=''''
	SET @sql1 = ''
	SELECT * from
	(SELECT
		start_date, Name_th, count_
	FROM cohort_size) t 
	PIVOT (
		SUM(count_) FOR Name_th IN (''+@columns+'')
	) AS pivot_table;''

	SET @sql2 = ''
	SELECT * from
	(SELECT
		start_date, Name_th, per
	FROM cohort_per) t 
	PIVOT (
		SUM(per) FOR Name_th IN (''+@columns+'')
	) AS pivot_table;''
	EXECUTE sp_executesql @sql1
	EXECUTE sp_executesql @sql2;'
	
EXEC sp_executesql @sqlToExecute, N'@s_date DATE ,@peri INT,@period NVARCHAR(20)', @s_date,@peri, @period
END
GO 
--@s_date: Ngày bắt đầu thê hiện bảng cần xem (có hoặc ko), @peri : số kỳ cần xem, @period: Xem cohort theo day/week/moth/quater
EXEC dbo.Pro_Cohort @s_date= '2013-01-01',@peri = 12, @period ='Month'