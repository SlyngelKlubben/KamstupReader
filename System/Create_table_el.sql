-- Table: public.el

-- DROP TABLE public.el;

CREATE TABLE public.el
(
  id integer NOT NULL DEFAULT nextval('el_id_seq'::regclass),
  "timestamp" timestamp without time zone DEFAULT now(),
  content text,
  CONSTRAINT el_pkey PRIMARY KEY (id)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE public.el
  OWNER TO pi;
GRANT ALL ON TABLE public.el TO pi;
GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE public.el TO iot;
