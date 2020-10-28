CREATE EXTENSION postgis;

/* importowanie danych shp */
-- a) Wyznacz liczbę budynków (tabela: popp, atrybut: f_codedesc, reprezentowane, jako punkty) położonych w odległości mniejszej niż 100000 m od głównych rzek. Budynki spełniające to kryterium zapisz do osobnej tabeli tableB.
--tworzenie tabeli
CREATE TABLE tabela_B (
gid INT,
cat FLOAT,
type CHAR(80),
f_codedesc CHAR(80),
geom GEOMETRY
)
--polizenie budynkow
SELECT COUNT(ST_DWithin(m.geom,p.geom,100000)) l_budynkow FROM majrivers m, popp p 
WHERE  (ST_DWithin(m.geom,p.geom,100000))='true' AND p.f_codedesc='Building'
--wpisywanie danych
INSERT INTO tabela_B
SELECT p.gid, p.cat, p.type, p.f_codedesc, p.geom FROM majrivers m, popp p 
WHERE  (ST_DWithin(m.geom,p.geom,100000))='true' AND p.f_codedesc='Building'
--sprawdzenie
SELECT * FROM tabela_b

--b) Utwórz tabelę o nazwie airportsNew. Z tabeli airports do zaimportuj nazwy lotnisk, ich geometrię, a także atrybut elev, reprezentujący wysokość n.p.m.  
CREATE TABLE new_Airports (
	id INT,
	name char(80),
	geom GEOMETRY,
	elev FLOAT
)

INSERT INTO new_Airports
SELECT a.id,a.name,a.geom,a.elev FROM airports a

-------- a)Znajdź lotnisko, które położone jest najbardziej na zachód i najbardziej na wschód.  
SELECT a.name, a.geom AS EW FROM airports a WHERE ST_X(a.geom) IN (SELECT MAX(ST_X(a.geom)) FROM airports a) OR ST_X(a.geom) IN (SELECT MIN(ST_X(a.geom)) FROM airports a)
-------- b) Do tabeli airportsNew dodaj nowy obiekt - lotnisko, które położone jest w punkcie środkowym drogi pomiędzy lotniskami znalezionymi w punkcie a. Lotnisko nazwij airportB. Wysokość n.p.m. przyjmij dowolną.
--wyznaczenie srodka miedzy punktami wschod zachod
SELECT ST_CENTROID(ST_SHORTESTLINE(
	(SELECT a.geom FROM airports a WHERE ST_X(a.geom) IN (SELECT MAX(ST_X(a.geom)) FROM airports a)),
	(SELECT a.geom FROM airports a WHERE ST_X(a.geom) IN (SELECT MIN(ST_X(a.geom)) FROM airports a))
)) AS centralny FROM airports a LIMIT 1 ;
-- wstawienie do tabeli danej 
INSERT INTO new_Airports VALUES('77','airportb', (SELECT ST_CENTROID(ST_SHORTESTLINE(
	(SELECT a.geom FROM airports a WHERE ST_X(a.geom) IN (SELECT MAX(ST_X(a.geom)) FROM airports a)),
	(SELECT a.geom FROM airports a WHERE ST_X(a.geom) IN (SELECT MIN(ST_X(a.geom)) FROM airports a))
)) AS centralny FROM airports a LIMIT 1) ,'234')
-- sprawdzenie
SELECT * FROM new_Airports na WHERE na.name='airportb' 

-- c) Wyznacz pole powierzchni obszaru, który oddalony jest mniej niż 1000 jednostek od najkrótszej linii łączącej jezioro o nazwie ‘Iliamna Lake’ i lotnisko o nazwie „AMBLER”
SELECT ST_AREA(ST_BUFFER((ST_SHORTESTLINE((SELECT a.geom FROM airports a WHERE a.name='AMBLER'),(SELECT l.geom FROM lakes l WHERE l.names='Iliamna Lake'))),1000)) pole FROM  airports a, lakes l LIMIT 1

-- d) Napisz zapytanie, które zwróci sumaryczne pole powierzchni poligonów reprezentujących poszczególne typy drzew znajdujących się na obszarze tundry i bagien.  
SELECT  (SUM(t.area_km2)+SUM(s.areakm2)) suma,tr.vegdesc gatunek FROM  trees tr, tundra t , swamp s
WHERE t.area_km2  
IN (SELECT t.area_km2 FROM tundra t, trees tr WHERE ST_CONTAINS(tr.geom,t.geom) = 'true') AND
s.areakm2  
IN (SELECT s.areakm2 FROM swamp s, trees tr WHERE ST_CONTAINS(tr.geom,s.geom) = 'true')
GROUP BY tr.vegdesc