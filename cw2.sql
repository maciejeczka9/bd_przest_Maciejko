CREATE DATABASE cw2;
CREATE EXTENSION postgis;


CREATE TABLE IF NOT EXISTS budynki
(
id_b  INT PRIMARY KEY UNIQUE NOT NULL,
geometria_b GEOMETRY, 
nazwa_b VARCHAR(30)
);

CREATE TABLE IF NOT EXISTS drogi
(
id_d  INT PRIMARY KEY UNIQUE NOT NULL,
geometria_d GEOMETRY, 
nazwa_d VARCHAR(30)
);

CREATE TABLE IF NOT EXISTS punkty_informacyjne
(
id_p  INT PRIMARY KEY UNIQUE NOT NULL,
geometria_p GEOMETRY, 
nazwa_p VARCHAR(30)
);

INSERT INTO budynki VALUES (1,ST_GeomFromText('POLYGON((8 1.5,8 4, 10.5 4, 10.5 1.5, 8 1.5))',0),'BuildingA');
INSERT INTO budynki VALUES (2,ST_GeomFromText('POLYGON((4 5,4 7,6 7,6 5,4 5))',0),'BuildingB');
INSERT INTO budynki VALUES (3,ST_GeomFromText('POLYGON((3 6,3 8,5 8,5 6,3 6))',0),'BuildingC');
INSERT INTO budynki VALUES (4,ST_GeomFromText('POLYGON((9 8,9 9,10 9,10 8,9 8))',0),'BuildingD');
INSERT INTO budynki VALUES (5,ST_GeomFromText('POLYGON((1 1 ,1 2,2 2,2 1,1 1))',0),'BuildingF');

INSERT INTO punkty_informacyjne VALUES (1,ST_GeomFromText('POINT(1 3.5)',0),'G');
INSERT INTO punkty_informacyjne VALUES (2,ST_GeomFromText('POINT(5.5 1.5)',0),'H');
INSERT INTO punkty_informacyjne VALUES (3,ST_GeomFromText('POINT(9.5 6)',0),'I');
INSERT INTO punkty_informacyjne VALUES (4,ST_GeomFromText('POINT(6.5 6)',0),'J');
INSERT INTO punkty_informacyjne VALUES (5,ST_GeomFromText('POINT(6 9.5)',0),'K');

INSERT INTO drogi VALUES (1,ST_GeomFromText('LINESTRING(0 4.5, 12 4.5)',0),'RoadX');
INSERT INTO drogi VALUES (2,ST_GeomFromText('LINESTRING(7.5 10.5, 7.5 0)',0),'RoadY');

-- zad6
-- a) Wyznacz całkowitą długość dróg w analizowanym mieście. 
SELECT SUM(ST_LENGTH(d.geometria)) AS dl_drogi FROM drogi d;
-- b) Wypisz geometrię (WKT), pole powierzchni oraz obwód poligonu reprezentującego budynek o nazwie BuildingA. 
SELECT ST_AsText(b.geometria_b) geometria, ST_AREA(geometria_b) pole,ST_PERIMETER(geometria_b) obwod FROM budynki b WHERE b.nazwa_b='BulidingA';
-- c) Wypisz nazwy i pola powierzchni wszystkich poligonów w warstwie budynki. Wyniki posortuj alfabetycznie.  
SELECT b.nazwa_b, ST_AREA(b.geometria_b) pole FROM budynki b ORDER BY nazwa_b;
-- d) Wypisz nazwy i obwody 2 budynków o największej powierzchni. 
SELECT b.nazwa_b, ST_PERIMETER(b.geometria_b) pole FROM budynki b ORDER BY ST_PERIMETER(b.geometria_b) DESC LIMIT 2; 
-- e) Wyznacz najkrótszą odległość między budynkiem BuildingC a punktem G.
SELECT ST_DISTANCE(b.geometria_b,p.geometria_p) FROM budynki b, punkty_informacyjne p WHERE b.nazwa_b='BuildingC' AND p.nazwa_p='G'  
--lub
SELECT ST_DISTANCE((SELECT b.geometria_b FROM budynki b WHERE b.nazwa_b='BulidingC'),(SELECT p.geometria_p FROM punkty_informacyjne p WHERE p.nazwa_p='G')) FROM budynki b, punkty_informacyjne p 
-- f) Wypisz pole powierzchni tej części budynku BuildingC, która znajduje się w odległości większej niż 0.5 od budynku BuildingB. 
SELECT ST_AREA(ST_DIFFERENCE((SELECT b.geometria_b FROM budynki b WHERE b.nazwa_b='BuildingC'),ST_BUFFER((SELECT b.geometria_b FROM budynki b WHERE b.nazwa_b='BulidingB'),0.5))) pole FROM budynki b LIMIT 1
-- g) Wybierz te budynki, których centroid (ST_Centroid) znajduje się powyżej drogi o nazwie RoadX.  
SELECT b.nazwa_b, ST_AsText(ST_Centroid(b.geometria_b)) AS centrum FROM budynki b WHERE ST_Y(ST_Centroid(b.geometria_b)) > (SELECT ST_Y(ST_Centroid(d.geometria)) FROM drogi d WHERE nazwa LIKE 'RoadX');
-- h)  Oblicz pole powierzchni tych części budynku BuildingC i poligonu o współrzędnych (4 7, 6 7, 6 8, 4 8, 4 7), które nie są wspólne dla tych dwóch obiektów.
SELECT ST_AREA(ST_SymDifference(b.geometria_b,ST_GeomFromText('POLYGON((4 7,6 7,6 8,4 8,4 7))',0))) FROM budynki b WHERE b.nazwa_b='BuildingC';

