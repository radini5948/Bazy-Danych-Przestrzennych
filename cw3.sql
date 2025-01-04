--zadanie 1
SELECT * FROM t2019_kar_buildings b2019
LEFT JOIN t2018_kar_buildings b2018
ON ST_EQUALS(b2019.geom, b2018.geom)
WHERE b2018.geom IS NULL OR NOT ST_EQUALS(b2019.geom, b2018.geom)

--zadanie 2
CREATE TABLE nowe_punkty_500 AS
SELECT 
    p2019.type, 
    COUNT(*) AS poi_count
FROM 
    T2019_KAR_POI_TABLE p2019
JOIN 
    t2019_kar_buildings b
    ON ST_DWithin(p2019.geom, b.geom, 500) 
WHERE 
    NOT EXISTS (
        SELECT 1 
        FROM T2018_KAR_POI_TABLE p2018 
        WHERE p2019.gid = p2018.gid
    )
GROUP BY 
    p2019.type;
	
--zadanie 3

CREATE TABLE streets_reprojected AS
SELECT 
    gid, 
    ST_Transform(geom, 31468) AS geometry
FROM 
    T2019_KAR_STREETS;
	
--zadanie 4
CREATE TABLE input_points (
    gid SERIAL PRIMARY KEY,
    geom GEOMETRY(Point, 4326) 
);

INSERT INTO input_points (geom)
VALUES 
    (ST_SetSRID(ST_Point(8.36093, 49.03174), 4326)),
    (ST_SetSRID(ST_Point(8.39876, 49.00644), 4326));
	
--zadanie 5

ALTER TABLE input_points
  ALTER COLUMN geom TYPE geometry(Point, 31468)
  USING ST_Transform(geom, 31468);

--zadanie 6

WITH input_line AS (
    SELECT ST_MakeLine(geom ORDER BY gid) AS geometry
    FROM input_points
)
SELECT sn.*
FROM T2019_KAR_STREET_NODE sn
WHERE ST_DWithin(
    ST_Transform(sn.geom, 31468), 
    (SELECT geometry FROM input_line), 
    200
);

--zadanie 7

SELECT 
    land.type, 
    COUNT(*) AS sporting_goods_store_count
FROM 
    T2019_KAR_POI_TABLE poi
JOIN 
    T2019_KAR_LAND_USE_A land
    ON ST_DWithin(poi.geom, land.geom, 300)
WHERE 
    poi.type = 'Sporting Goods Store' 
    AND land.type = 'Park (City/County)'
GROUP BY 
    land.type;
	
--zadanie 8

CREATE TABLE T2019_KAR_BRIDGES AS
SELECT 
    ST_Intersection(r.geom, w.geom) AS geometry
FROM 
    T2019_KAR_RAILWAYS r
JOIN 
    T2019_KAR_WATER_LINES w
    ON ST_Intersects(r.geom, w.geom)
WHERE 
    ST_GeometryType(ST_Intersection(r.geom, w.geom)) = 'ST_Point';