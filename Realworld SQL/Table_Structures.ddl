with t1 as
	(select count(distinct games) as total_games 
	from olympics_history
	where season = 'Summer'),
	t2 as 
	(select distinct sport, games
	 from olympics_history
	 where season = 'Summer' order by games
	),
	t3 as
	(select sport, count(*) as no_of_games
	 from t2
	 group by sport
	)
select *
from t3
join t1
	on t3.no_of_games = t1.total_games