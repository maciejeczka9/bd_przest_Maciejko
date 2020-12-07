-- połączenie rastrów 
CREATE TABLE public."scalone" AS 
SELECT ST_Union( geom)
FROM public."Exports" e