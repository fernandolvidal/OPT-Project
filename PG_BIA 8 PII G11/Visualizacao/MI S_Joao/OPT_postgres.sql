- ***** Criação da estrutura de dados da rede STCP no PGADMIN ***** -

-- data_rede_postgres - Tabela original
-- tabela de paragens 

DROP TABLE data_rede_postgres;

CREATE TABLE data_rede_postgres
(
	id serial NOT NULL,
	PROVIDER_ID INT,
	PROVIDER_NAME VARCHAR(20),
	LINE_ID INT,
	LINE_CODE VARCHAR(20),
	LINE_GO_NAME VARCHAR(50),
	LINE_RETURN_NAME VARCHAR(50),
	PATH_ID INT,
	ORIENTATION VARCHAR(7),
	PATH_CODE VARCHAR(20),
	PATHSTOP_ID INT,
	PATHSTOP_STOPORDER INT,
	PATHSTOP_PREVDISTANCE INT,
	STOP_CODE VARCHAR(20),
	STOP_SHORTNAME VARCHAR(50),
	STOP_NAME VARCHAR(50),
	STOP_KEY VARCHAR(50),
	STOP_LATITUDE DOUBLE PRECISION,
	STOP_LONGITUDE DOUBLE PRECISION,
	POSTAL_CODE VARCHAR(8),
	ID_LAT_LON VARCHAR(7)
)

TRUNCATE TABLE data_rede_postgres;

SELECT * 
FROM data_rede_postgres;

COPY data_rede_postgres
FROM 'C:\tmp\dim_rede.csv' DELIMITER ',' CSV HEADER;

SELECT AddGeometryColumn('data_rede_postgres', 'geom', 4326, 'POINT', 2);
UPDATE data_rede_postgres SET geom = ST_SetSRID(ST_MakePoint(STOP_LONGITUDE, STOP_LATITUDE), 4326);  

- ***** Queries rede STCP ***** -

# paragens de uma dada linha, mostrando a área do concelho do Porto
select geom
from data_rede_postgres
where line_id = 7761
union all
select ST_Transform(geom, 4326) as Poligono
from cont_aad_caop2018
where concelho = 'PORTO';

-- get all the points inside polygons
SELECT b.geom
FROM data_rede_postgres b, cont_aad_caop2018 a
where 
line_id = 7761 and concelho = 'PORTO' and ST_Contains(ST_Transform(a.geom,4326), b.geom) = 'TRUE'
union all
select ST_Transform(geom, 4326) as Poligono
from cont_aad_caop2018
where concelho = 'PORTO';

- paragens dos STCP fora do concelho do Porto
-- get all the points outside polygons
SELECT geom
FROM data_rede_postgres
where 
-- line_id = 7761 and 
geom not in (
SELECT b.geom
FROM data_rede_postgres b, cont_aad_caop2018 a
where 
-- line_id = 7761 and 
concelho = 'PORTO' and ST_Contains(ST_Transform(a.geom,4326), b.geom) = 'TRUE')
union all
select ST_Transform(geom, 4326) as Poligono
from cont_aad_caop2018
where concelho = 'PORTO';

-- mostrar uma linha específica e um só sentiido
SELECT *
from data_rede_postgres a
where line_id = 7761 and orientation = 'R';

- ***** Criação da estrutura de dados dos dias 23/06 e 24/06 no PGADMIN ***** -

-- Amostra S. João dias 23/06/2019 e 24/06/2019
-- sample_sjoao_log_scheds e sample_sjoao_log_load - Tabela original

DROP TABLE sample_sjoao_log_load;

CREATE TABLE sample_sjoao_log_load
(
--	id_novo serial NOT NULL,
	ID BIGINT,
	USER_NAME VARCHAR(9),
	TYPE_OF_REQUEST VARCHAR(11),
	REQUEST_DATE TIMESTAMP,
	RESPONSE_DATE TIMESTAMP,
	REQUEST_SERVICE VARCHAR(17),
	REQUEST_DESC VARCHAR(50),
	TICKET VARCHAR(108),
	RESPONSE_DESC VARCHAR(50),
	REQUEST_LATITUDE DOUBLE PRECISION,
	REQUEST_LONGITUDE DOUBLE PRECISION
);


DROP TABLE sample_sjoao_log_scheds;
CREATE TABLE sample_sjoao_log_scheds
(
--	id_novo serial NOT NULL,
	ID BIGINT,
	USER_NAME VARCHAR(9),
	TYPE_OF_REQUEST VARCHAR(11),
	REQUEST_DATE TIMESTAMP,
	RESPONSE_DATE TIMESTAMP,
	REQUEST_SERVICE VARCHAR(17),
	REQUEST_DESC VARCHAR(50),
	TICKET VARCHAR(108),
	RESPONSE_DESC TEXT,
	REQUEST_LATITUDE DOUBLE PRECISION,
	REQUEST_LONGITUDE DOUBLE PRECISION
);

TRUNCATE TABLE sample_sjoao_log_load;
TRUNCATE TABLE sample_sjoao_log_scheds;

SELECT * 
FROM sample_sjoao_log_load;

SELECT *
FROM sample_sjoao_log_scheds;

COPY sample_sjoao_log_load
FROM 'C:\tmp\sample_sjoao_log_load.csv' DELIMITER ',' CSV HEADER;

SELECT AddGeometryColumn('sample_sjoao_log_load', 'geom', 4326, 'POINT', 2);
UPDATE sample_sjoao_log_load SET geom = ST_SetSRID(ST_MakePoint(REQUEST_LONGITUDE, REQUEST_LATITUDE), 4326);  


COPY sample_sjoao_log_scheds
FROM 'C:\tmp\sample_sjoao_log_scheds.csv' DELIMITER ',' CSV HEADER;

SELECT AddGeometryColumn('sample_sjoao_log_scheds', 'geom', 4326, 'POINT', 2);
UPDATE sample_sjoao_log_scheds SET geom = ST_SetSRID(ST_MakePoint(REQUEST_LONGITUDE, REQUEST_LATITUDE), 4326);  


SELECT geom
FROM sample_sjoao_log_load
union all
select ST_Transform(geom, 4326) as Poligono
from cont_aad_caop2018
where concelho = 'PORTO';


SELECT * 
FROM cont_aad_caop2018;

- ***** Queries sample ***** -

-- get all the points inside polygons Distrito Porto 
SELECT b.geom Porto
FROM sample_sjoao_log_load b, cont_aad_caop2018 a
where 
concelho = 'PORTO' and ST_Contains(ST_Transform(a.geom,4326), b.geom) = 'TRUE';
union all
select ST_Transform(geom, 4326) as Poligono
from cont_aad_caop2018
where concelho = 'PORTO';

select freguesia, count(*)
from cont_aad_caop2018
where concelho = 'PORTO'
group by freguesia
order by freguesia

-- get all the points log_scheds 0n 23rd and 24th June; just play with dates and times
SELECT b.geom
FROM sample_sjoao_log_scheds b
where 
request_date > '2019-06-23 09:00:00' and request_date < '2019-06-23 09:59:00'
union all
select ST_Transform(geom, 4326) as Poligono
from cont_aad_caop2018
where concelho = 'PORTO' and freguesia = 'União das freguesias de Cedofeita, Santo Ildefonso, Sé, Miragaia, São Nicolau e Vitória';
