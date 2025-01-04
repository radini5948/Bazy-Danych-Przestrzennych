create table obiekty (
    id integer primary key,
    nazwa varchar(50),
    geom geometry
);

insert into obiekty (id, nazwa, geom) 
values 
    (1, 'obiekt1', ST_GeomFromText('COMPOUNDCURVE(LINESTRING(0 1, 1 1), CIRCULARSTRING(1 1, 2 0, 3 1), CIRCULARSTRING(3 1, 4 2, 5 1), LINESTRING(5 1, 6 1))')),
    (2, 'obiekt2', ST_GeomFromText('GEOMETRYCOLLECTION(COMPOUNDCURVE(LINESTRING(10 6, 14 6), CIRCULARSTRING(14 6, 16 4, 14 2), CIRCULARSTRING(14 2, 12 0, 10 2), LINESTRING(10 2, 10 6)), COMPOUNDCURVE(CIRCULARSTRING(11 2, 12 3, 13 2), CIRCULARSTRING(13 2, 12 1, 11 2)))')),
    (3, 'obiekt3', ST_GeomFromText('COMPOUNDCURVE(LINESTRING(10 17, 12 13), LINESTRING(12 13, 7 15), LINESTRING(7 15, 10 17))')),
    (4, 'obiekt4', ST_GeomFromText('COMPOUNDCURVE(LINESTRING(20 20, 25 25), LINESTRING(25 25, 27 24), LINESTRING(27 24, 25 22), LINESTRING(25 22, 26 21), LINESTRING(26 21, 22 19), LINESTRING(22 19, 20.5 19.5))')),
    (5, 'obiekt5', ST_GeomFromText('GEOMETRYCOLLECTION(POINT Z (30 30 59), POINT Z (38 32 234))')),
    (6, 'obiekt6', ST_GeomFromText('GEOMETRYCOLLECTION(LINESTRING(1 1, 3 2), POINT(4 2))'));

delete from obiekty where id = 7;
--ZAD 2
select ST_Area(ST_Buffer(ST_ShortestLine(
    (select geom from obiekty where id = 3),
    (select geom from obiekty where id = 4)
), 5));
--ZAD 3
update obiekty 
set geom = ST_MakePolygon(ST_LineMerge(ST_Collect(
    geom, 
    ST_GeomFromText('LINESTRING(20.5 19.5, 20 20)')
))) 
where id = 4;
--ZAD 4
insert into obiekty (id, nazwa, geom)
values (
    7, 
    'obiekt7', 
    ST_Union(ARRAY(
        select geom 
        from obiekty 
        where id in (3, 4)
    ))
);
--ZAD 5
select SUM(ST_Area(ST_Buffer(geom, 5))) 
from obiekty 
where NOT ST_HasArc(geom);