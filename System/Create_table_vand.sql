-- Table: public.vand

-- DROP TABLE public.vand;

CREATE TABLE public.vand
(
  id integer NOT NULL DEFAULT nextval('vand_id_seq'::regclass),
  "timestamp" timestamp without time zone DEFAULT now(),
  content text,
  CONSTRAINT vand_pkey PRIMARY KEY (id)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE public.vand
  OWNER TO pi;
GRANT ALL ON TABLE public.vand TO pi;
GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE public.vand TO iot;
