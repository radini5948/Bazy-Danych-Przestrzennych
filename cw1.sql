--zadanie 1 
select * from public.gole
WHERE teamid ='POL'
--zadanie 2
select * from public.gole
WHERE matchid = '1004'
--zadanie 3
select  pg.player, pg.teamid, pm.stadium, pm.mdate
FROM public.mecze pm
JOIN public.gole pg ON pg.matchid = pm.id
WHERE teamid='POL'


--zadanie 4
select  pg.player, pg.teamid, pm.stadium, pm.mdate, pm.team1, pm.team2
FROM public.mecze pm
JOIN public.gole pg ON pg.matchid = pm.id
WHERE pg.player LIKE 'Mario%'

--zadanie 5
select pg.player, pg.teamid, pg.gtime, pd.coach
FROM public.gole pg
JOIN public.druzyny pd ON pd.id = pg.teamid
WHERE pg.gtime<=10;

--zadanie 6
select pd.coach, pd.teamname, pm.mdate
FROM public.druzyny pd
JOIN public.mecze pm ON pm.team1 =pd.id OR pm.team2 =pd.id
WHERE pd.coach = 'Franciszek Smuda'

--zadanie 7
select pg.player, pm.stadium
FROM public.gole pg
JOIN public.mecze pm ON pm.id = pg.matchid
WHERE stadium = 'National Stadium, Warsaw'

--zadanie 8

SELECT pg.player, COUNT(pg.player) AS gole
FROM public.gole pg 
JOIN public.mecze pm on pg.matchid = pm.id
WHERE pm.team1 = 'GER' AND pg.teamid != 'GER' OR pm.team2='GER' AND pg.teamid != 'GER'
GROUP BY pg.player 
ORDER BY gole DESC;

--zadanie 9

SELECT pd.teamname, COUNT(pg.player) AS liczba_goli
FROM public.gole pg 
JOIN public.druzyny pd ON pg.teamid = pd.id 
GROUP BY pd.teamname 
ORDER BY liczba_goli DESC;

--zadanie 10

SELECT pm.stadium, COUNT(pg.player) AS liczba_goli 
FROM public.gole pg 
JOIN public.mecze pm ON pg.matchid = pm.id 
GROUP BY pm.stadium 
ORDER BY liczba_goli DESC;
