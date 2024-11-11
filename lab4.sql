create database cw2;
CREATE EXTENSION postgis;

create table roads (id int, geometry geometry, name varchar(50)));
create table poi (id int primary key not null, geometry geometry, name varchar(50));
create table buildings (id int primary key not null, geometry geometry, name varchar(50));

insert into roads (id, name, geometry) values
(1, 'RoadX', 'LINESTRING(0 4.5, 12 4.5)'),
(2, 'RoadY', 'LINESTRING(7.5 10.5, 7.5 0)');

insert into poi (id, geometry, name) values 
(1,'POINT(6 9.5)','K'), (2,'POINT(6.5 6)','J'), 
(3,'POINT(9.5 6)','I'), (4,'POINT(1 3.5)','G'), 
(5,'POINT(5.5 1.5)','H');

insert into buildings (id, geometry, name) values 
(1,'POLYGON((9 9, 10 9, 10 8, 9 8, 9 9))','BuildingD'),
(2,'POLYGON((3 8, 5 8, 5 6, 3 6, 3 8))','BuildingC'),
(3,'POLYGON((4 7, 6 7, 6 5, 4 5, 4 7))','BuildingB'),
(4,'POLYGON((8 4, 10.5 4, 10.5 1.5, 8 1.5, 8 4))','BuildingA'),
(5,'POLYGON((1 2, 2 2, 2 1, 1 1, 1 2))','BuildingF');

--A
SELECT * FROM buildings
SELECT SUM(ST_Length(geometry)) 
from roads

--B
SELECT ST_Astext(geometry), ST_Area(geometry), ST_Perimeter(geometry) 
FROM buildings 
WHERE NAME = 'BuildingA';

--C
SELECT NAME, st_area(geometry) 
FROM buildings 
ORDER BY NAME ASC;

--D
SELECT NAME, ST_Perimeter(geometry) 
FROM buildings 
ORDER BY ST_Area(geometry) 
DESC LIMIT 2;

--E
SELECT round(ST_Distance(buildings.geometry, poi.geometry)::numeric,2) as dist
FROM buildings, poi 
WHERE buildings.name = 'BuildingC' AND poi.name = 'K';

--F
SELECT ROUNG(ST_Area(ST_Difference(geometry, ST_Buffer((SELECT geometry FROM buildings WHERE NAME = 'BuildingB'), 0.5)))::NUMERIC,2)
FROM buildings 
WHERE NAME = 'BuildingC';

--G
SELECT * FROM buildings
WHERE (SELECT ST_Y(ST_Centroid(geometry)) < ST_Y(ST_Centroid(buildings.geometry)) 
FROM roads 
WHERE NAME = 'RoadX');

--H
SELECT ST_Area(ST_Symdifference(geometry, ST_GeomFromText('POLYGON((4 7, 6 7, 6 8, 4 8, 4 7))'))) 
FROM buildings 
WHERE NAME = 'BuildingC';