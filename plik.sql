--w CMD
-- cd C:\Program Files\PostgreSQL\12\bin
-- 1) ładowanie rastru przy użyciu pliku .sql
raster2pgsql -s 3763 -N -32767 -t 100x100 -I -C -M -d 
C:\Users\macie\Desktop\DokumentyMagdy\studia\5sem\BazyDanych\5\rasters\rasters\srtm_1arc_v3.tif rasters.dem > C:\Users\macie\Desktop\DokumentyMagdy\studia\5sem\BazyDanych\5\dem.sql
/* -s raster wyjsciowy o okreslonym SRID
   -N wartosc NoData do uzycia na pasmach bez wartosci NoData
   -t wytnij raster na plytki, aby wstawic po jednym w kazdym wierszu tabeli (WIDTHxHEIGHT)
   -I utworz przeglad rastra , gdy wiecej niz jeden oddziel przecinkiem
   -C 
   -M analiza prozniowa tabeli rastrowej
   -d 
*/
-- zaladowac rozszerzenie postgis_raster
-- 2) ładowanie rastru bezpośrednio do bazy
raster2pgsql -s 3763 -N -32767 -t 100x100 -I -C -M -d C:\Users\macie\Desktop\DokumentyMagdy\studia\5sem\BazyDanych\5\rasters\rasters\srtm_1arc_v3.tif rasters.dem | psql -d a_raster -h localhost -U postgres -p 5432
-- 3) załadowanie danych landsat8 o wielkości kafelka 128x128 bezpośrednio do bazy danych.
raster2pgsql.exe -s 3763 -N -32767 -t 128x128 -I -C -M -d C:\Users\macie\Desktop\DokumentyMagdy\studia\5sem\BazyDanych\5\rasters\rasters\Landsat8_L1TP_RGBN.TIF rasters.landsat8 | psql -d a_raster -h localhost -U postgres -p 5432

-- 4) wyodrębnienie kafelkow nakładających się na geometrię
-- przecięcie rastra z wektorem //intersects - nazwa tabeli
CREATE TABLE schema_magda.intersects AS
SELECT a.rast, b.municipality
FROM rasters.dem AS a, vectors.porto_parishes AS b
WHERE ST_Intersects(a.rast, b.geom) AND b.municipality ilike 'porto';
-- dodanie serial primary key
alter table schema_magda.intersects
add column rid SERIAL PRIMARY KEY;
-- utworzenie indeksu przestrzennego
CREATE INDEX idx_intersects_rast_gist ON schema_magda.intersects
USING gist (ST_ConvexHull(rast));
--dodawanie raster constraints
-- schema::name table_name::name raster_column::name
SELECT AddRasterConstraints('schema_magda'::name,
'intersects'::name,'rast'::name);
-- obcinanie rastra na podstawie wektora //clip - nazwa tabeli
CREATE TABLE schema_magda.clip AS
SELECT ST_Clip(a.rast, b.geom, true), b.municipality
FROM rasters.dem AS a, vectors.porto_parishes AS b
WHERE ST_Intersects(a.rast, b.geom) AND b.municipality like 'PORTO';
-- polaczenie wielu kafelkow w jeden raster //union - nazwa tabeli
CREATE TABLE schema_Magda.union AS
SELECT ST_Union(ST_Clip(a.rast, b.geom, true))
FROM rasters.dem AS a, vectors.porto_parishes AS b
WHERE b.municipality ilike 'porto' and ST_Intersects(b.geom,a.rast);
-- użycie funkcji ST_AsRaster w celu rastrowania tabeli z parafiami o takiej samej charakterystyce przestrzennej tj.: wielkość piksela, zakresy itp.
CREATE TABLE schema_Magda.porto_parishes AS
WITH r AS (
SELECT rast FROM rasters.dem
LIMIT 1
)
SELECT ST_AsRaster(a.geom,r.rast,'8BUI',a.id,-32767) AS rast
FROM vectors.porto_parishes AS a, r
WHERE a.municipality ilike 'porto';

-- 5) łączy rekordy przy użyciu funkcji ST_UNION w pojedynczy raster.
DROP TABLE schema_magda.porto_parishes; --> drop table porto_parishes first
CREATE TABLE schema_magda.porto_parishes AS
WITH r AS (
SELECT rast FROM rasters.dem
LIMIT 1
)
SELECT st_union(ST_AsRaster(a.geom,r.rast,'8BUI',a.id,-32767)) AS rast
FROM vectors.porto_parishes AS a, r
WHERE a.municipality ilike 'porto';

-- 6) po uzyskaniu pojedynczego rastra można generować kafelki za pomocą funkcji ST_Tile.
DROP TABLE schema_magda.porto_parishes; --> drop table porto_parishes first
CREATE TABLE schema_magda.porto_parishes AS
WITH r AS (
SELECT rast FROM rasters.dem
LIMIT 1 
)
SELECT st_tile(st_union(ST_AsRaster(a.geom,r.rast,'8BUI',a.id,-32767)),128,128,true,-32767) AS rast
FROM vectors.porto_parishes AS a, r
WHERE a.municipality ilike 'porto';

-- 7) użycie funkcji ST_Intersection i ST_DumpAsPolygons - konwersja rasterów na wektory
/*ST_Clip zwraca raster, a ST_Intersection zwraca zestaw par wartości geometria-piksel, ponieważ ta funkcja przekształca raster w wektor przed rzeczywistym „klipem”.*/
CREATE TABLE schema_magda.intersection as
SELECT a.rid,(ST_Intersection(b.geom,a.rast)).geom,(ST_Intersection(b.geom,a.rast)).val
FROM rasters.landsat8 AS a, vectors.porto_parishes AS b
WHERE b.parish ilike 'paranhos' and ST_Intersects(b.geom,a.rast);
-- konwertuje rastry w wektory (poligony)
CREATE TABLE schema_magda.dumppolygons AS
SELECT a.rid,(ST_DumpAsPolygons(ST_Clip(a.rast,b.geom))).geom,(ST_DumpAsPolygons(ST_Clip(a.rast,b.geom))).val
FROM rasters.landsat8 AS a, vectors.porto_parishes AS b
WHERE b.parish ilike 'paranhos' and ST_Intersects(b.geom,a.rast);


-- 8) analiza rastrowania
-- funkcja ST_Band służy do wyodrębniania pasm z rastra
CREATE TABLE schema_magda.landsat_nir AS
SELECT rid, ST_Band(rast,4) AS rast
FROM rasters.landsat8;
-- ST_Clip może być użyty do wycięcia rastra z innego rastra
CREATE TABLE schema_magda.paranhos_dem AS
SELECT a.rid,ST_Clip(a.rast, b.geom,true) as rast
FROM rasters.dem AS a, vectors.porto_parishes AS b
WHERE b.parish ilike 'paranhos' and ST_Intersects(b.geom,a.rast);
-- ST_Slope generuje nachylenie przy użyciu poprzednio wygenerowanej tabeli (wzniesienie)
CREATE TABLE schema_magda.paranhos_slope AS
SELECT a.rid,ST_Slope(a.rast,1,'32BF','PERCENTAGE') as rast
FROM schema_magda.paranhos_dem AS a;
-- funkcja ST_Reclass, by zreklasyfikować raster
CREATE TABLE schema_magda.paranhos_slope_reclass AS
SELECT a.rid,ST_Reclass(a.rast,1,']0-15]:1, (15-30]:2, (30-9999:3', '32BF',0)
FROM schema_magda.paranhos_slope AS a;
-- funkcja ST_SummaryStats by obliczyć statystyki rastra
SELECT ST_SummaryStats(a.rast) AS stats
FROM schema_magda.paranhos_dem AS a;
-- przy użyciu UNION można wygenerować jedną statystykę wybranego rastra
SELECT ST_SummaryStats(ST_Union(a.rast))
FROM schema_magda.paranhos_dem AS a;
-- ST_SummaryStats z lepszą kontrolą złożonego typu danych
WITH t AS (
SELECT ST_SummaryStats(ST_Union(a.rast)) AS stats
FROM schema_magda.paranhos_dem AS a
)
SELECT (stats).min,(stats).max,(stats).mean FROM t;
-- ST_SummaryStats w połączeniu z GROUP BY, by wyświetlić statystykę dla każdego poligonu "parish" można użyć polecenia GROUP BY
WITH t AS (
SELECT b.parish AS parish, st_summarystats(ST_Union(ST_Clip(a.rast, b.geom,true))) AS stats
FROM rasters.dem AS a, vectors.porto_parishes AS b
WHERE b.municipality ilike 'porto' and ST_Intersects(b.geom,a.rast)
group by b.parish
)
SELECT parish,(stats).min,(stats).max,(stats).mean FROM t;
-- Funkcja ST_Value pozwala wyodrębnić wartość piksela z punktu lub zestawu punktów
/* Ponieważ geometria punktów jest wielopunktowa, 
a funkcja ST_Value wymaga geometrii jednopunktowej, 
należy przekonwertować geometrię wielopunktową na geometrię 
jednopunktową za pomocą funkcji (ST_Dump(b.geom)).geom. */
SELECT b.name,st_value(a.rast,(ST_Dump(b.geom)).geom) AS wartosc_piksela
FROM
rasters.dem a, vectors.places AS b
WHERE ST_Intersects(a.rast,b.geom)
ORDER BY b.name;

-- 9) Topographic Position Index (TPI) - porównuje wysokość każdej komórki w DEM ze średnią wysokością określonego sąsiedztwa wokół tej komórki.
-- funkcja ST_Value pozwala na utworzenie mapy TPI z DEM wysokości.
CREATE TABLE schema_magda.tpi30 as
SELECT ST_TPI(a.rast,1) as rast
FROM rasters.dem a;
-- ma rozdzielczość 30 metrów i TPI używa tylko jednej komórki sąsiedztwa do obliczeń
-- indeks przestrzenny
CREATE INDEX idx_tpi30_rast_gist ON schema_magda.tpi30
USING gist (ST_ConvexHull(rast));
-- dodanie constraintów
SELECT AddRasterConstraints('schema_magda'::name, 'tpi30'::name,'rast'::name);

-- zadanie 
CREATE TABLE schema_magda.tpi30_porto as
SELECT ST_TPI(a.rast,1) as rast
FROM rasters.dem a, vectors.porto_parishes AS b WHERE  ST_Intersects(a.rast, b.geom) AND b.municipality ilike 'porto'

CREATE INDEX idx_tpi30_porto_rast_gist ON schema_magda.tpi30_porto
USING gist (ST_ConvexHull(rast));

SELECT AddRasterConstraints('schema_magda'::name, 'tpi30_porto'::name,'rast'::name);

-- 10) algebra map 
/* Istnieją dwa sposoby korzystania z algebry map: 
   1) użycie wyrażenia
   2) użycie funkcji zwrotnej
   
   NDVI=(NIR-Red)/(NIR+Red)
*/
-- uzycie MapAlgebra
CREATE TABLE schema_magda.porto_ndvi AS
WITH r AS (
SELECT a.rid,ST_Clip(a.rast, b.geom,true) AS rast
FROM rasters.landsat8 AS a, vectors.porto_parishes AS b
WHERE b.municipality ilike 'porto' and ST_Intersects(b.geom,a.rast)
)
SELECT
r.rid,ST_MapAlgebra(
r.rast, 1,
r.rast, 4,
'([rast2.val] - [rast1.val]) / ([rast2.val] + [rast1.val])::float','32BF'
) AS rast
FROM r;
-- indeks przestrzenny
CREATE INDEX idx_porto_ndvi_rast_gist ON schema_magda.porto_ndvi
USING gist (ST_ConvexHull(rast));
-- dodanie constraintów
SELECT AddRasterConstraints('schema_magda'::name, 'porto_ndvi'::name,'rast'::name);
-- funkcja zwrotna 
-- utworzenie funkcji, która bedzie wywolana później
CREATE OR REPLACE FUNCTION schema_magda.ndvi(
VALUE double precision [] [] [],
pos integer [][],
VARIADIC userargs text []
)
RETURNS double precision AS
$$
BEGIN
--RAISE NOTICE 'Pixel Value: %', value [1][1][1];-->For debug purposes
RETURN (value [2][1][1] - value [1][1][1])/(value [2][1][1]+value [1][1][1]); --> NDVI calculation!
END;
$$
LANGUAGE 'plpgsql' IMMUTABLE COST 1000;
-- w kwerendzie algebry map
CREATE TABLE schema_magda.porto_ndvi2 AS
WITH r AS (
SELECT a.rid,ST_Clip(a.rast, b.geom,true) AS rast
FROM rasters.landsat8 AS a, vectors.porto_parishes AS b
WHERE b.municipality ilike 'porto' and ST_Intersects(b.geom,a.rast)
)
SELECT
r.rid,ST_MapAlgebra(
r.rast, ARRAY[1,4],
'schema_magda.ndvi(double precision[], integer[],text[])'::regprocedure, --> This is the function!
'32BF'::text
-- indeks przestrzenny 
CREATE INDEX idx_porto_ndvi2_rast_gist ON schema_magda.porto_ndvi2
USING gist (ST_ConvexHull(rast));
-- dodanie constraintow
SELECT AddRasterConstraints('schema_magda'::name, 'porto_ndvi2'::name,'rast'::name);

-- 10) funkcja TPI wykorzystuje algebrę mapy z wywołaniem funkcji

-- 11) eksport danych
-- funkcja ST_AsTiff tworzy dane wyjściowe jako binarną reprezentację pliku tiff
SELECT ST_AsTiff(ST_Union(rast))
FROM schema_magda.porto_ndvi;
-- funkcja ST_AsGDALRaster nie zapisuje danych wyjściowych bezpośrednio na dysku, natomiast dane wyjściowe są reprezentacją binarną dowolnego formatu GDAL
SELECT ST_AsGDALRaster(ST_Union(rast), 'GTiff', ARRAY['COMPRESS=DEFLATE', 'PREDICTOR=2', 'PZLEVEL=9'])
FROM schema_magda.porto_ndvi;

-- 12) zapisywanie danych na dysku za pomocą dużego obiektu
CREATE TABLE tmp_out AS
SELECT lo_from_bytea(0,
ST_AsGDALRaster(ST_Union(rast), 'GTiff', ARRAY['COMPRESS=DEFLATE', 'PREDICTOR=2', 'PZLEVEL=9'])
) AS loid
FROM schema_magda.porto_ndvi;
-- eksport
SELECT lo_export(loid, 'D:\myraster.tiff') --> Save the file in a place where the user postgres have access. In windows a flash drive usualy works fine.
FROM tmp_out;
-- 
SELECT lo_unlink(loid)
FROM tmp_out; --> Delete the large object.

-- 13) użycie gdal
gdal_translate -co COMPRESS=DEFLATE -co PREDICTOR=2 -co ZLEVEL=9 PG:"host=localhost port=5432 dbname=a_raster user=postgres password=1234 schema=schema_magda table=porto_ndvi mode=2" porto_ndvi.tiff

-- GDAL obsługuje rastry PostGIS, możliwe jest opublikowanie rastra jako WMS.
-- 14) Mapfile