Drop table if exists Warehouse;
CREATE TABLE Warehouse (
    ID VARCHAR(10),
    OnHandQuantity INT,
    OnHandQuantityDelta INT,
    event_type VARCHAR(10),
    event_datetime TIMESTAMP
);
insert into warehouse values
('SH0013', 278,   99 ,   'OutBound', '2020-05-25 0:25'), 
('SH0012', 377,   31 ,   'InBound',  '2020-05-24 22:00'),
('SH0011', 346,   1  ,   'OutBound', '2020-05-24 15:01'),
('SH0010', 346,   1  ,   'OutBound', '2020-05-23 5:00'),
('SH009',  348,   102,   'InBound',  '2020-04-25 18:00'),
('SH008',  246,   43 ,   'InBound',  '2020-04-25 2:00'),
('SH007',  203,   2  ,   'OutBound', '2020-02-25 9:00'),
('SH006',  205,   129,   'OutBound', '2020-02-18 7:00'),
('SH005',  334,   1  ,   'OutBound', '2020-02-18 8:00'),
('SH004',  335,   27 ,   'OutBound', '2020-01-29 5:00'),
('SH003',  362,   120,   'InBound',  '2019-12-31 2:00'),
('SH002',  242,   8  ,   'OutBound', '2019-05-22 0:50'),
('SH001',  250,   250,   'InBound',  '2019-05-20 0:45');
COMMIT;
 
 with WH as 
		(select * from warehouse order by event_datetime DESC),
	days as 
		(select OnHandquantity, event_datetime, 
		DATE_SUB(event_datetime, INTERVAL 90 DAY) as day90,
		DATE_SUB(event_datetime, INTERVAL 180 DAY) as day180,
		DATE_SUB(event_datetime, INTERVAL 270 DAY) as day270,
		DATE_SUB(event_datetime, INTERVAL 365 DAY) as day365
        from WH limit 1),
        
	inv_90_days as 
		(select coalesce(sum(onhandquantitydelta),0) as DaysOld_90
        from WH cross join days d
        where WH.event_type = "InBound"
        and WH.event_datetime >= d.day90),
	inv_90_days_final as 
		(Select case when DaysOld_90 > d.OnHandquantity Then d.OnHandquantity
					else DaysOld_90
                    end as DaysOld_90
		From inv_90_days
        Cross join days d),
        
	inv_180_days as 
		(Select coalesce(sum(onhandquantitydelta),0) as DaysOld_180
        FROM WH Cross Join days d
        Where WH.event_type = "InBound"
        AND WH.event_datetime between d.day180 and d.day90 
        ),
	inv_180_days_final as 
		(Select Case when DaysOld_180 > (d.OnHandquantity - DaysOld_90) Then (d.OnHandquantity - DaysOld_90)
					Else DaysOld_180
                    END as DaysOld_180
        FROM inv_180_days
        Cross Join days d
        Cross Join inv_90_days_final
        ),
        
	inv_270_days as
		(Select coalesce(sum(OnhandquantityDelta),0) as DaysOld_270
		FROM WH
		Cross Join days d
		Where WH.Event_type = "InBound" 
		AND WH.Event_datetime between d.day180 and d.day270)   ,
	inv_270_days_final as
		(Select case when DaysOld_270 > (d.OnHandquantity - (DaysOld_180 + DaysOld_90)) Then (d.Onhandquantity - (DaysOld_180 + DaysOld_90))
					Else DaysOld_270
                    END as DaysOld_270
        FROM inv_270_days 
        cross join days d
        cross join inv_180_days_final
        cross join inv_90_days_final),
        
	inv_365_days as
		(Select coalesce(sum(OnhandquantityDelta),0) as DaysOld_365
		FROM WH
		Cross Join days d
		Where WH.Event_type = "InBound" 
		AND WH.Event_datetime between d.day365 and d.day270) ,  
	inv_365_days_final as
		(Select case when DaysOld_365 > (d.Onhandquantity - (DaysOld_180 + DaysOld_90 + DaysOld_270)) Then (d.Onhandquantity - (DaysOld_180 + DaysOld_90 + DaysOld_270))
					Else DaysOld_365
                    END as DaysOld_365
        FROM inv_365_days 
        cross join days d
        cross join inv_180_days_final
        cross join inv_90_days_final
        cross join inv_270_days_final)
        
SELECT DaysOld_90 as "0-90 Days Old",
	   DaysOld_180 as "90-180 Days Old",
	   DaysOld_270 as "180-270 Days Old",
	   DaysOld_365 as "170-365 Days Old"
FROM inv_90_days_final 
Cross JOIN inv_180_days_final 
cross join inv_270_days_final 
cross join inv_365_days 




