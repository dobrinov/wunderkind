\restrict P8WYYXyeKXxadUDH3lTwdiN8adlnEK8guZhdyF77AbuEqSF2NvqzWpl6M88VnQ3

-- Dumped from database version 18.1 (Postgres.app)
-- Dumped by pg_dump version 18.1 (Postgres.app)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: active_storage_attachments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.active_storage_attachments (
    id bigint NOT NULL,
    name character varying NOT NULL,
    record_type character varying NOT NULL,
    record_id bigint NOT NULL,
    blob_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL
);


--
-- Name: active_storage_attachments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.active_storage_attachments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: active_storage_attachments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.active_storage_attachments_id_seq OWNED BY public.active_storage_attachments.id;


--
-- Name: active_storage_blobs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.active_storage_blobs (
    id bigint NOT NULL,
    key character varying NOT NULL,
    filename character varying NOT NULL,
    content_type character varying,
    metadata text,
    service_name character varying NOT NULL,
    byte_size bigint NOT NULL,
    checksum character varying,
    created_at timestamp(6) without time zone NOT NULL
);


--
-- Name: active_storage_blobs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.active_storage_blobs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: active_storage_blobs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.active_storage_blobs_id_seq OWNED BY public.active_storage_blobs.id;


--
-- Name: active_storage_variant_records; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.active_storage_variant_records (
    id bigint NOT NULL,
    blob_id bigint NOT NULL,
    variation_digest character varying NOT NULL
);


--
-- Name: active_storage_variant_records_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.active_storage_variant_records_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: active_storage_variant_records_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.active_storage_variant_records_id_seq OWNED BY public.active_storage_variant_records.id;


--
-- Name: ar_internal_metadata; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ar_internal_metadata (
    key character varying NOT NULL,
    value character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: assignment_questions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.assignment_questions (
    id bigint NOT NULL,
    assignment_id bigint NOT NULL,
    question_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    "position" integer NOT NULL
);


--
-- Name: assignment_questions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.assignment_questions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: assignment_questions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.assignment_questions_id_seq OWNED BY public.assignment_questions.id;


--
-- Name: assignments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.assignments (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    completed_at timestamp without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    feedback_after_answer boolean,
    kind integer DEFAULT 0 NOT NULL
);


--
-- Name: assignments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.assignments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: assignments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.assignments_id_seq OWNED BY public.assignments.id;


--
-- Name: badge_awards; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.badge_awards (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    badge_key character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL
);


--
-- Name: badge_awards_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.badge_awards_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: badge_awards_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.badge_awards_id_seq OWNED BY public.badge_awards.id;


--
-- Name: possible_answers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.possible_answers (
    id bigint NOT NULL,
    question_id bigint NOT NULL,
    value text NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    correct boolean DEFAULT false NOT NULL,
    "position" integer DEFAULT 0 NOT NULL
);


--
-- Name: possible_answers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.possible_answers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: possible_answers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.possible_answers_id_seq OWNED BY public.possible_answers.id;


--
-- Name: question_images; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.question_images (
    id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: question_images_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.question_images_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: question_images_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.question_images_id_seq OWNED BY public.question_images.id;


--
-- Name: question_scripts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.question_scripts (
    id bigint NOT NULL,
    code text NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: question_scripts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.question_scripts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: question_scripts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.question_scripts_id_seq OWNED BY public.question_scripts.id;


--
-- Name: questions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.questions (
    id bigint NOT NULL,
    text text,
    answer text,
    explanation text,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    elo integer DEFAULT 1200 NOT NULL,
    attachable_type character varying,
    attachable_id bigint,
    attachable_parameters jsonb,
    body jsonb NOT NULL,
    body_text text NOT NULL,
    answer_type integer DEFAULT 1 NOT NULL,
    grading jsonb DEFAULT '{}'::jsonb NOT NULL,
    status integer DEFAULT 0 NOT NULL,
    grade_min integer,
    grade_max integer,
    author_id bigint,
    CONSTRAINT questions_attachable_consistency CHECK (((attachable_id IS NULL) OR ((attachable_id IS NOT NULL) AND (attachable_type IS NOT NULL))))
);


--
-- Name: questions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.questions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: questions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.questions_id_seq OWNED BY public.questions.id;


--
-- Name: questions_topics; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.questions_topics (
    topic_id bigint NOT NULL,
    question_id bigint NOT NULL
);


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version character varying NOT NULL
);


--
-- Name: skills; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.skills (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    topic_id bigint NOT NULL,
    rating integer DEFAULT 1200 NOT NULL,
    games_count integer DEFAULT 0 NOT NULL,
    last_practiced_at timestamp(6) without time zone,
    review_due_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: skills_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.skills_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: skills_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.skills_id_seq OWNED BY public.skills.id;


--
-- Name: topics; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.topics (
    id bigint NOT NULL,
    name character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    slug character varying NOT NULL,
    "position" integer DEFAULT 0 NOT NULL,
    parent_id bigint
);


--
-- Name: topics_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.topics_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: topics_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.topics_id_seq OWNED BY public.topics.id;


--
-- Name: user_answers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_answers (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    assignment_question_id bigint NOT NULL,
    value text NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    correct boolean NOT NULL,
    response jsonb NOT NULL,
    duration_ms integer
);


--
-- Name: user_answers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.user_answers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_answers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.user_answers_id_seq OWNED BY public.user_answers.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id bigint NOT NULL,
    name character varying NOT NULL,
    email character varying NOT NULL,
    password_digest character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    elo integer DEFAULT 1200 NOT NULL,
    feedback_after_answer boolean DEFAULT false NOT NULL,
    role integer DEFAULT 0 NOT NULL,
    nickname character varying,
    locale character varying DEFAULT 'bg'::character varying NOT NULL,
    daily_minutes_target integer,
    total_xp integer DEFAULT 0 NOT NULL,
    current_streak integer DEFAULT 0 NOT NULL,
    longest_streak integer DEFAULT 0 NOT NULL,
    last_active_on date,
    streak_freezes integer DEFAULT 0 NOT NULL
);


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: xp_events; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.xp_events (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    amount integer NOT NULL,
    reason character varying NOT NULL,
    source_type character varying,
    source_id bigint,
    created_at timestamp(6) without time zone NOT NULL
);


--
-- Name: xp_events_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.xp_events_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: xp_events_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.xp_events_id_seq OWNED BY public.xp_events.id;


--
-- Name: active_storage_attachments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_attachments ALTER COLUMN id SET DEFAULT nextval('public.active_storage_attachments_id_seq'::regclass);


--
-- Name: active_storage_blobs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_blobs ALTER COLUMN id SET DEFAULT nextval('public.active_storage_blobs_id_seq'::regclass);


--
-- Name: active_storage_variant_records id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_variant_records ALTER COLUMN id SET DEFAULT nextval('public.active_storage_variant_records_id_seq'::regclass);


--
-- Name: assignment_questions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assignment_questions ALTER COLUMN id SET DEFAULT nextval('public.assignment_questions_id_seq'::regclass);


--
-- Name: assignments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assignments ALTER COLUMN id SET DEFAULT nextval('public.assignments_id_seq'::regclass);


--
-- Name: badge_awards id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.badge_awards ALTER COLUMN id SET DEFAULT nextval('public.badge_awards_id_seq'::regclass);


--
-- Name: possible_answers id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.possible_answers ALTER COLUMN id SET DEFAULT nextval('public.possible_answers_id_seq'::regclass);


--
-- Name: question_images id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.question_images ALTER COLUMN id SET DEFAULT nextval('public.question_images_id_seq'::regclass);


--
-- Name: question_scripts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.question_scripts ALTER COLUMN id SET DEFAULT nextval('public.question_scripts_id_seq'::regclass);


--
-- Name: questions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.questions ALTER COLUMN id SET DEFAULT nextval('public.questions_id_seq'::regclass);


--
-- Name: skills id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.skills ALTER COLUMN id SET DEFAULT nextval('public.skills_id_seq'::regclass);


--
-- Name: topics id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.topics ALTER COLUMN id SET DEFAULT nextval('public.topics_id_seq'::regclass);


--
-- Name: user_answers id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_answers ALTER COLUMN id SET DEFAULT nextval('public.user_answers_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Name: xp_events id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.xp_events ALTER COLUMN id SET DEFAULT nextval('public.xp_events_id_seq'::regclass);


--
-- Name: active_storage_attachments active_storage_attachments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_attachments
    ADD CONSTRAINT active_storage_attachments_pkey PRIMARY KEY (id);


--
-- Name: active_storage_blobs active_storage_blobs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_blobs
    ADD CONSTRAINT active_storage_blobs_pkey PRIMARY KEY (id);


--
-- Name: active_storage_variant_records active_storage_variant_records_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_variant_records
    ADD CONSTRAINT active_storage_variant_records_pkey PRIMARY KEY (id);


--
-- Name: ar_internal_metadata ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- Name: assignment_questions assignment_questions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assignment_questions
    ADD CONSTRAINT assignment_questions_pkey PRIMARY KEY (id);


--
-- Name: assignments assignments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assignments
    ADD CONSTRAINT assignments_pkey PRIMARY KEY (id);


--
-- Name: badge_awards badge_awards_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.badge_awards
    ADD CONSTRAINT badge_awards_pkey PRIMARY KEY (id);


--
-- Name: possible_answers possible_answers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.possible_answers
    ADD CONSTRAINT possible_answers_pkey PRIMARY KEY (id);


--
-- Name: question_images question_images_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.question_images
    ADD CONSTRAINT question_images_pkey PRIMARY KEY (id);


--
-- Name: question_scripts question_scripts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.question_scripts
    ADD CONSTRAINT question_scripts_pkey PRIMARY KEY (id);


--
-- Name: questions questions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.questions
    ADD CONSTRAINT questions_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: skills skills_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.skills
    ADD CONSTRAINT skills_pkey PRIMARY KEY (id);


--
-- Name: topics topics_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.topics
    ADD CONSTRAINT topics_pkey PRIMARY KEY (id);


--
-- Name: user_answers user_answers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_answers
    ADD CONSTRAINT user_answers_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: xp_events xp_events_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.xp_events
    ADD CONSTRAINT xp_events_pkey PRIMARY KEY (id);


--
-- Name: index_active_storage_attachments_on_blob_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_active_storage_attachments_on_blob_id ON public.active_storage_attachments USING btree (blob_id);


--
-- Name: index_active_storage_attachments_uniqueness; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_active_storage_attachments_uniqueness ON public.active_storage_attachments USING btree (record_type, record_id, name, blob_id);


--
-- Name: index_active_storage_blobs_on_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_active_storage_blobs_on_key ON public.active_storage_blobs USING btree (key);


--
-- Name: index_active_storage_variant_records_uniqueness; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_active_storage_variant_records_uniqueness ON public.active_storage_variant_records USING btree (blob_id, variation_digest);


--
-- Name: index_assignment_questions_on_assignment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_assignment_questions_on_assignment_id ON public.assignment_questions USING btree (assignment_id);


--
-- Name: index_assignment_questions_on_assignment_id_and_position; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_assignment_questions_on_assignment_id_and_position ON public.assignment_questions USING btree (assignment_id, "position");


--
-- Name: index_assignment_questions_on_assignment_id_and_question_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_assignment_questions_on_assignment_id_and_question_id ON public.assignment_questions USING btree (assignment_id, question_id);


--
-- Name: index_assignment_questions_on_question_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_assignment_questions_on_question_id ON public.assignment_questions USING btree (question_id);


--
-- Name: index_assignments_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_assignments_on_user_id ON public.assignments USING btree (user_id);


--
-- Name: index_badge_awards_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_badge_awards_on_user_id ON public.badge_awards USING btree (user_id);


--
-- Name: index_badge_awards_on_user_id_and_badge_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_badge_awards_on_user_id_and_badge_key ON public.badge_awards USING btree (user_id, badge_key);


--
-- Name: index_possible_answers_on_question_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_possible_answers_on_question_id ON public.possible_answers USING btree (question_id);


--
-- Name: index_questions_on_author_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_questions_on_author_id ON public.questions USING btree (author_id);


--
-- Name: index_questions_topics_on_question_id_and_topic_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_questions_topics_on_question_id_and_topic_id ON public.questions_topics USING btree (question_id, topic_id);


--
-- Name: index_questions_topics_on_topic_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_questions_topics_on_topic_id ON public.questions_topics USING btree (topic_id);


--
-- Name: index_skills_on_topic_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_skills_on_topic_id ON public.skills USING btree (topic_id);


--
-- Name: index_skills_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_skills_on_user_id ON public.skills USING btree (user_id);


--
-- Name: index_skills_on_user_id_and_topic_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_skills_on_user_id_and_topic_id ON public.skills USING btree (user_id, topic_id);


--
-- Name: index_topics_on_parent_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_topics_on_parent_id ON public.topics USING btree (parent_id);


--
-- Name: index_topics_on_slug; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_topics_on_slug ON public.topics USING btree (slug);


--
-- Name: index_user_answers_on_assignment_question_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_user_answers_on_assignment_question_id ON public.user_answers USING btree (assignment_question_id);


--
-- Name: index_user_answers_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_user_answers_on_user_id ON public.user_answers USING btree (user_id);


--
-- Name: index_users_on_lower_email; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_lower_email ON public.users USING btree (lower((email)::text));


--
-- Name: index_xp_events_on_source; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_xp_events_on_source ON public.xp_events USING btree (source_type, source_id);


--
-- Name: index_xp_events_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_xp_events_on_user_id ON public.xp_events USING btree (user_id);


--
-- Name: index_xp_events_on_user_id_and_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_xp_events_on_user_id_and_created_at ON public.xp_events USING btree (user_id, created_at);


--
-- Name: badge_awards fk_rails_0434c93bfb; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.badge_awards
    ADD CONSTRAINT fk_rails_0434c93bfb FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: assignment_questions fk_rails_529fe162b7; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assignment_questions
    ADD CONSTRAINT fk_rails_529fe162b7 FOREIGN KEY (assignment_id) REFERENCES public.assignments(id);


--
-- Name: topics fk_rails_5f3c091f12; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.topics
    ADD CONSTRAINT fk_rails_5f3c091f12 FOREIGN KEY (parent_id) REFERENCES public.topics(id);


--
-- Name: xp_events fk_rails_62162c3432; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.xp_events
    ADD CONSTRAINT fk_rails_62162c3432 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: skills fk_rails_696734696b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.skills
    ADD CONSTRAINT fk_rails_696734696b FOREIGN KEY (topic_id) REFERENCES public.topics(id);


--
-- Name: active_storage_variant_records fk_rails_993965df05; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_variant_records
    ADD CONSTRAINT fk_rails_993965df05 FOREIGN KEY (blob_id) REFERENCES public.active_storage_blobs(id);


--
-- Name: assignments fk_rails_aa6b76dac2; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assignments
    ADD CONSTRAINT fk_rails_aa6b76dac2 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: user_answers fk_rails_b8a843d293; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_answers
    ADD CONSTRAINT fk_rails_b8a843d293 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: active_storage_attachments fk_rails_c3b3935057; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_attachments
    ADD CONSTRAINT fk_rails_c3b3935057 FOREIGN KEY (blob_id) REFERENCES public.active_storage_blobs(id);


--
-- Name: questions fk_rails_d96516e73c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.questions
    ADD CONSTRAINT fk_rails_d96516e73c FOREIGN KEY (author_id) REFERENCES public.users(id);


--
-- Name: assignment_questions fk_rails_e28ceafe2a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assignment_questions
    ADD CONSTRAINT fk_rails_e28ceafe2a FOREIGN KEY (question_id) REFERENCES public.questions(id);


--
-- Name: skills fk_rails_ee47b87d76; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.skills
    ADD CONSTRAINT fk_rails_ee47b87d76 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: possible_answers fk_rails_f255fee41e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.possible_answers
    ADD CONSTRAINT fk_rails_f255fee41e FOREIGN KEY (question_id) REFERENCES public.questions(id);


--
-- Name: user_answers fk_rails_f2ac802668; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_answers
    ADD CONSTRAINT fk_rails_f2ac802668 FOREIGN KEY (assignment_question_id) REFERENCES public.assignment_questions(id);


--
-- PostgreSQL database dump complete
--

\unrestrict P8WYYXyeKXxadUDH3lTwdiN8adlnEK8guZhdyF77AbuEqSF2NvqzWpl6M88VnQ3

SET search_path TO "$user", public;

INSERT INTO "schema_migrations" (version) VALUES
('20260820000009'),
('20260820000008'),
('20260820000007'),
('20260820000006'),
('20260820000005'),
('20260820000004'),
('20260820000003'),
('20260820000002'),
('20260820000001'),
('20251116160149'),
('20251025064141'),
('20251018063919'),
('20251011063410'),
('20251004084341'),
('20251004083752'),
('20251004083717'),
('20251004083350'),
('20250618070509'),
('20250403090217');

