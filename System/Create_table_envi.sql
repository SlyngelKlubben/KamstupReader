-- Table: public.envi

-- DROP TABLE public.envi;

CREATE TABLE public.envi
(
  id integer NOT NULL DEFAULT nextval('envi_id_seq'::regclass),
  "timestamp" timestamp without time zone DEFAULT now(),
  content text,
  senid text,
  temp double precision,
  humi double precision,
  pir boolean,
  CONSTRAINT envi_pkey PRIMARY KEY (id)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE public.envi
  OWNER TO pi;
GRANT ALL ON TABLE public.envi TO pi;
GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE public.envi TO iot;
