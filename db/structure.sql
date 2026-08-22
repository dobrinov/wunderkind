\restrict sWeQsOdUR3bPj5FcjQYieR20wD6YkkFwrtqklEDVh0S98eG8SlkoYh62NDeWElW

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
    "position" integer NOT NULL,
    hints_revealed integer DEFAULT 0 NOT NULL
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
    kind integer DEFAULT 0 NOT NULL,
    homework_id bigint,
    hints_allowed boolean
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
-- Name: challenge_answers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.challenge_answers (
    id bigint NOT NULL,
    challenge_participant_id bigint NOT NULL,
    challenge_question_id bigint NOT NULL,
    value character varying NOT NULL,
    response jsonb DEFAULT '{}'::jsonb NOT NULL,
    correct boolean NOT NULL,
    duration_ms integer NOT NULL,
    points integer DEFAULT 0 NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: challenge_answers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.challenge_answers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: challenge_answers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.challenge_answers_id_seq OWNED BY public.challenge_answers.id;


--
-- Name: challenge_participants; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.challenge_participants (
    id bigint NOT NULL,
    challenge_id bigint NOT NULL,
    user_id bigint NOT NULL,
    score integer DEFAULT 0 NOT NULL,
    correct_count integer DEFAULT 0 NOT NULL,
    total_ms integer DEFAULT 0 NOT NULL,
    xp_earned integer DEFAULT 0 NOT NULL,
    question_started_at timestamp(6) without time zone,
    finished_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: challenge_participants_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.challenge_participants_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: challenge_participants_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.challenge_participants_id_seq OWNED BY public.challenge_participants.id;


--
-- Name: challenge_questions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.challenge_questions (
    id bigint NOT NULL,
    challenge_id bigint NOT NULL,
    question_id bigint NOT NULL,
    "position" integer NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: challenge_questions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.challenge_questions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: challenge_questions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.challenge_questions_id_seq OWNED BY public.challenge_questions.id;


--
-- Name: challenges; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.challenges (
    id bigint NOT NULL,
    status integer DEFAULT 0 NOT NULL,
    question_count integer NOT NULL,
    seconds_per_question integer NOT NULL,
    target_elo integer NOT NULL,
    started_at timestamp(6) without time zone,
    finished_at timestamp(6) without time zone,
    winner_id bigint,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: challenges_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.challenges_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: challenges_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.challenges_id_seq OWNED BY public.challenges.id;


--
-- Name: classroom_memberships; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.classroom_memberships (
    id bigint NOT NULL,
    classroom_id bigint NOT NULL,
    user_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: classroom_memberships_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.classroom_memberships_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: classroom_memberships_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.classroom_memberships_id_seq OWNED BY public.classroom_memberships.id;


--
-- Name: classrooms; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.classrooms (
    id bigint NOT NULL,
    teacher_id bigint NOT NULL,
    name character varying NOT NULL,
    invite_code character varying NOT NULL,
    leaderboard_enabled boolean DEFAULT true NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: classrooms_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.classrooms_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: classrooms_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.classrooms_id_seq OWNED BY public.classrooms.id;


--
-- Name: homework_questions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.homework_questions (
    id bigint NOT NULL,
    homework_id bigint NOT NULL,
    question_id bigint NOT NULL,
    "position" integer NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: homework_questions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.homework_questions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: homework_questions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.homework_questions_id_seq OWNED BY public.homework_questions.id;


--
-- Name: homeworks; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.homeworks (
    id bigint NOT NULL,
    assigner_id bigint NOT NULL,
    classroom_id bigint,
    title character varying NOT NULL,
    due_at timestamp(6) without time zone NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    hints_allowed boolean DEFAULT false NOT NULL
);


--
-- Name: homeworks_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.homeworks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: homeworks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.homeworks_id_seq OWNED BY public.homeworks.id;


--
-- Name: parent_links; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.parent_links (
    id bigint NOT NULL,
    parent_id bigint NOT NULL,
    child_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: parent_links_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.parent_links_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: parent_links_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.parent_links_id_seq OWNED BY public.parent_links.id;


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
-- Name: question_hints; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.question_hints (
    id bigint NOT NULL,
    question_id bigint NOT NULL,
    ladder jsonb DEFAULT '[]'::jsonb NOT NULL,
    wrong_answer_explanations jsonb DEFAULT '{}'::jsonb NOT NULL,
    model character varying,
    reviewed_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: question_hints_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.question_hints_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: question_hints_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.question_hints_id_seq OWNED BY public.question_hints.id;


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
-- Name: question_reports; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.question_reports (
    id bigint NOT NULL,
    question_id bigint NOT NULL,
    user_id bigint NOT NULL,
    reason integer NOT NULL,
    note text,
    status integer DEFAULT 0 NOT NULL,
    resolver_id bigint,
    resolved_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: question_reports_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.question_reports_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: question_reports_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.question_reports_id_seq OWNED BY public.question_reports.id;


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
    author_id bigint,
    suggested_by_id bigint,
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
    updated_at timestamp(6) without time zone NOT NULL,
    review_interval_days integer DEFAULT 1 NOT NULL,
    mastered_at timestamp(6) without time zone,
    deferred_until timestamp(6) without time zone
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
-- Name: topic_prerequisites; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.topic_prerequisites (
    id bigint NOT NULL,
    topic_id bigint NOT NULL,
    prerequisite_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: topic_prerequisites_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.topic_prerequisites_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: topic_prerequisites_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.topic_prerequisites_id_seq OWNED BY public.topic_prerequisites.id;


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
    duration_ms integer,
    skipped boolean DEFAULT false NOT NULL
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
    email character varying,
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
    streak_freezes integer DEFAULT 0 NOT NULL,
    link_code character varying,
    verified_at timestamp(6) without time zone,
    managed_by_id bigint
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
-- Name: challenge_answers id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.challenge_answers ALTER COLUMN id SET DEFAULT nextval('public.challenge_answers_id_seq'::regclass);


--
-- Name: challenge_participants id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.challenge_participants ALTER COLUMN id SET DEFAULT nextval('public.challenge_participants_id_seq'::regclass);


--
-- Name: challenge_questions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.challenge_questions ALTER COLUMN id SET DEFAULT nextval('public.challenge_questions_id_seq'::regclass);


--
-- Name: challenges id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.challenges ALTER COLUMN id SET DEFAULT nextval('public.challenges_id_seq'::regclass);


--
-- Name: classroom_memberships id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.classroom_memberships ALTER COLUMN id SET DEFAULT nextval('public.classroom_memberships_id_seq'::regclass);


--
-- Name: classrooms id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.classrooms ALTER COLUMN id SET DEFAULT nextval('public.classrooms_id_seq'::regclass);


--
-- Name: homework_questions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.homework_questions ALTER COLUMN id SET DEFAULT nextval('public.homework_questions_id_seq'::regclass);


--
-- Name: homeworks id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.homeworks ALTER COLUMN id SET DEFAULT nextval('public.homeworks_id_seq'::regclass);


--
-- Name: parent_links id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.parent_links ALTER COLUMN id SET DEFAULT nextval('public.parent_links_id_seq'::regclass);


--
-- Name: possible_answers id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.possible_answers ALTER COLUMN id SET DEFAULT nextval('public.possible_answers_id_seq'::regclass);


--
-- Name: question_hints id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.question_hints ALTER COLUMN id SET DEFAULT nextval('public.question_hints_id_seq'::regclass);


--
-- Name: question_images id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.question_images ALTER COLUMN id SET DEFAULT nextval('public.question_images_id_seq'::regclass);


--
-- Name: question_reports id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.question_reports ALTER COLUMN id SET DEFAULT nextval('public.question_reports_id_seq'::regclass);


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
-- Name: topic_prerequisites id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.topic_prerequisites ALTER COLUMN id SET DEFAULT nextval('public.topic_prerequisites_id_seq'::regclass);


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
-- Name: challenge_answers challenge_answers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.challenge_answers
    ADD CONSTRAINT challenge_answers_pkey PRIMARY KEY (id);


--
-- Name: challenge_participants challenge_participants_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.challenge_participants
    ADD CONSTRAINT challenge_participants_pkey PRIMARY KEY (id);


--
-- Name: challenge_questions challenge_questions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.challenge_questions
    ADD CONSTRAINT challenge_questions_pkey PRIMARY KEY (id);


--
-- Name: challenges challenges_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.challenges
    ADD CONSTRAINT challenges_pkey PRIMARY KEY (id);


--
-- Name: classroom_memberships classroom_memberships_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.classroom_memberships
    ADD CONSTRAINT classroom_memberships_pkey PRIMARY KEY (id);


--
-- Name: classrooms classrooms_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.classrooms
    ADD CONSTRAINT classrooms_pkey PRIMARY KEY (id);


--
-- Name: homework_questions homework_questions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.homework_questions
    ADD CONSTRAINT homework_questions_pkey PRIMARY KEY (id);


--
-- Name: homeworks homeworks_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.homeworks
    ADD CONSTRAINT homeworks_pkey PRIMARY KEY (id);


--
-- Name: parent_links parent_links_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.parent_links
    ADD CONSTRAINT parent_links_pkey PRIMARY KEY (id);


--
-- Name: possible_answers possible_answers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.possible_answers
    ADD CONSTRAINT possible_answers_pkey PRIMARY KEY (id);


--
-- Name: question_hints question_hints_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.question_hints
    ADD CONSTRAINT question_hints_pkey PRIMARY KEY (id);


--
-- Name: question_images question_images_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.question_images
    ADD CONSTRAINT question_images_pkey PRIMARY KEY (id);


--
-- Name: question_reports question_reports_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.question_reports
    ADD CONSTRAINT question_reports_pkey PRIMARY KEY (id);


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
-- Name: topic_prerequisites topic_prerequisites_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.topic_prerequisites
    ADD CONSTRAINT topic_prerequisites_pkey PRIMARY KEY (id);


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
-- Name: index_assignments_on_homework_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_assignments_on_homework_id ON public.assignments USING btree (homework_id);


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
-- Name: index_challenge_answers_on_challenge_participant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_challenge_answers_on_challenge_participant_id ON public.challenge_answers USING btree (challenge_participant_id);


--
-- Name: index_challenge_answers_on_challenge_question_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_challenge_answers_on_challenge_question_id ON public.challenge_answers USING btree (challenge_question_id);


--
-- Name: index_challenge_answers_on_participant_and_question; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_challenge_answers_on_participant_and_question ON public.challenge_answers USING btree (challenge_participant_id, challenge_question_id);


--
-- Name: index_challenge_participants_on_challenge_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_challenge_participants_on_challenge_id ON public.challenge_participants USING btree (challenge_id);


--
-- Name: index_challenge_participants_on_challenge_id_and_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_challenge_participants_on_challenge_id_and_user_id ON public.challenge_participants USING btree (challenge_id, user_id);


--
-- Name: index_challenge_participants_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_challenge_participants_on_user_id ON public.challenge_participants USING btree (user_id);


--
-- Name: index_challenge_questions_on_challenge_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_challenge_questions_on_challenge_id ON public.challenge_questions USING btree (challenge_id);


--
-- Name: index_challenge_questions_on_challenge_id_and_position; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_challenge_questions_on_challenge_id_and_position ON public.challenge_questions USING btree (challenge_id, "position");


--
-- Name: index_challenge_questions_on_challenge_id_and_question_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_challenge_questions_on_challenge_id_and_question_id ON public.challenge_questions USING btree (challenge_id, question_id);


--
-- Name: index_challenge_questions_on_question_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_challenge_questions_on_question_id ON public.challenge_questions USING btree (question_id);


--
-- Name: index_challenges_on_status_and_target_elo_and_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_challenges_on_status_and_target_elo_and_created_at ON public.challenges USING btree (status, target_elo, created_at);


--
-- Name: index_challenges_on_winner_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_challenges_on_winner_id ON public.challenges USING btree (winner_id);


--
-- Name: index_classroom_memberships_on_classroom_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_classroom_memberships_on_classroom_id ON public.classroom_memberships USING btree (classroom_id);


--
-- Name: index_classroom_memberships_on_classroom_id_and_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_classroom_memberships_on_classroom_id_and_user_id ON public.classroom_memberships USING btree (classroom_id, user_id);


--
-- Name: index_classroom_memberships_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_classroom_memberships_on_user_id ON public.classroom_memberships USING btree (user_id);


--
-- Name: index_classrooms_on_invite_code; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_classrooms_on_invite_code ON public.classrooms USING btree (invite_code);


--
-- Name: index_classrooms_on_teacher_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_classrooms_on_teacher_id ON public.classrooms USING btree (teacher_id);


--
-- Name: index_homework_questions_on_homework_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_homework_questions_on_homework_id ON public.homework_questions USING btree (homework_id);


--
-- Name: index_homework_questions_on_homework_id_and_position; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_homework_questions_on_homework_id_and_position ON public.homework_questions USING btree (homework_id, "position");


--
-- Name: index_homework_questions_on_homework_id_and_question_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_homework_questions_on_homework_id_and_question_id ON public.homework_questions USING btree (homework_id, question_id);


--
-- Name: index_homework_questions_on_question_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_homework_questions_on_question_id ON public.homework_questions USING btree (question_id);


--
-- Name: index_homeworks_on_assigner_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_homeworks_on_assigner_id ON public.homeworks USING btree (assigner_id);


--
-- Name: index_homeworks_on_classroom_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_homeworks_on_classroom_id ON public.homeworks USING btree (classroom_id);


--
-- Name: index_parent_links_on_child_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_parent_links_on_child_id ON public.parent_links USING btree (child_id);


--
-- Name: index_parent_links_on_parent_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_parent_links_on_parent_id ON public.parent_links USING btree (parent_id);


--
-- Name: index_parent_links_on_parent_id_and_child_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_parent_links_on_parent_id_and_child_id ON public.parent_links USING btree (parent_id, child_id);


--
-- Name: index_possible_answers_on_question_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_possible_answers_on_question_id ON public.possible_answers USING btree (question_id);


--
-- Name: index_question_hints_on_question_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_question_hints_on_question_id ON public.question_hints USING btree (question_id);


--
-- Name: index_question_reports_on_question_id_and_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_question_reports_on_question_id_and_user_id ON public.question_reports USING btree (question_id, user_id);


--
-- Name: index_question_reports_on_resolver_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_question_reports_on_resolver_id ON public.question_reports USING btree (resolver_id);


--
-- Name: index_question_reports_on_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_question_reports_on_status ON public.question_reports USING btree (status);


--
-- Name: index_question_reports_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_question_reports_on_user_id ON public.question_reports USING btree (user_id);


--
-- Name: index_questions_on_author_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_questions_on_author_id ON public.questions USING btree (author_id);


--
-- Name: index_questions_on_elo; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_questions_on_elo ON public.questions USING btree (elo);


--
-- Name: index_questions_on_suggested_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_questions_on_suggested_by_id ON public.questions USING btree (suggested_by_id);


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
-- Name: index_topic_prerequisites_on_prerequisite_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_topic_prerequisites_on_prerequisite_id ON public.topic_prerequisites USING btree (prerequisite_id);


--
-- Name: index_topic_prerequisites_on_topic_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_topic_prerequisites_on_topic_id ON public.topic_prerequisites USING btree (topic_id);


--
-- Name: index_topic_prerequisites_on_topic_id_and_prerequisite_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_topic_prerequisites_on_topic_id_and_prerequisite_id ON public.topic_prerequisites USING btree (topic_id, prerequisite_id);


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

CREATE UNIQUE INDEX index_user_answers_on_assignment_question_id ON public.user_answers USING btree (assignment_question_id);


--
-- Name: index_user_answers_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_user_answers_on_user_id ON public.user_answers USING btree (user_id);


--
-- Name: index_users_on_link_code; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_link_code ON public.users USING btree (link_code);


--
-- Name: index_users_on_lower_email; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_lower_email ON public.users USING btree (lower((email)::text));


--
-- Name: index_users_on_managed_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_managed_by_id ON public.users USING btree (managed_by_id);


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
-- Name: homeworks fk_rails_09f3dbfbc4; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.homeworks
    ADD CONSTRAINT fk_rails_09f3dbfbc4 FOREIGN KEY (assigner_id) REFERENCES public.users(id);


--
-- Name: challenge_answers fk_rails_0b83f6ff24; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.challenge_answers
    ADD CONSTRAINT fk_rails_0b83f6ff24 FOREIGN KEY (challenge_participant_id) REFERENCES public.challenge_participants(id);


--
-- Name: challenge_participants fk_rails_30dff451a7; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.challenge_participants
    ADD CONSTRAINT fk_rails_30dff451a7 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: classrooms fk_rails_33e9cf11b8; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.classrooms
    ADD CONSTRAINT fk_rails_33e9cf11b8 FOREIGN KEY (teacher_id) REFERENCES public.users(id);


--
-- Name: question_hints fk_rails_3a1bbd2110; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.question_hints
    ADD CONSTRAINT fk_rails_3a1bbd2110 FOREIGN KEY (question_id) REFERENCES public.questions(id);


--
-- Name: homework_questions fk_rails_4050471fe9; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.homework_questions
    ADD CONSTRAINT fk_rails_4050471fe9 FOREIGN KEY (homework_id) REFERENCES public.homeworks(id);


--
-- Name: assignment_questions fk_rails_529fe162b7; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assignment_questions
    ADD CONSTRAINT fk_rails_529fe162b7 FOREIGN KEY (assignment_id) REFERENCES public.assignments(id);


--
-- Name: homeworks fk_rails_5ab24daddc; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.homeworks
    ADD CONSTRAINT fk_rails_5ab24daddc FOREIGN KEY (classroom_id) REFERENCES public.classrooms(id);


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
-- Name: homework_questions fk_rails_69a8a9a0e7; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.homework_questions
    ADD CONSTRAINT fk_rails_69a8a9a0e7 FOREIGN KEY (question_id) REFERENCES public.questions(id);


--
-- Name: parent_links fk_rails_72f451c9b8; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.parent_links
    ADD CONSTRAINT fk_rails_72f451c9b8 FOREIGN KEY (child_id) REFERENCES public.users(id);


--
-- Name: questions fk_rails_78048761b5; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.questions
    ADD CONSTRAINT fk_rails_78048761b5 FOREIGN KEY (suggested_by_id) REFERENCES public.users(id);


--
-- Name: classroom_memberships fk_rails_792695bbce; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.classroom_memberships
    ADD CONSTRAINT fk_rails_792695bbce FOREIGN KEY (classroom_id) REFERENCES public.classrooms(id);


--
-- Name: question_reports fk_rails_7caf886700; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.question_reports
    ADD CONSTRAINT fk_rails_7caf886700 FOREIGN KEY (resolver_id) REFERENCES public.users(id);


--
-- Name: parent_links fk_rails_7dbe6246b5; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.parent_links
    ADD CONSTRAINT fk_rails_7dbe6246b5 FOREIGN KEY (parent_id) REFERENCES public.users(id);


--
-- Name: challenge_participants fk_rails_7fd31647c0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.challenge_participants
    ADD CONSTRAINT fk_rails_7fd31647c0 FOREIGN KEY (challenge_id) REFERENCES public.challenges(id);


--
-- Name: challenge_questions fk_rails_89a87831d3; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.challenge_questions
    ADD CONSTRAINT fk_rails_89a87831d3 FOREIGN KEY (question_id) REFERENCES public.questions(id);


--
-- Name: topic_prerequisites fk_rails_8e54d3337b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.topic_prerequisites
    ADD CONSTRAINT fk_rails_8e54d3337b FOREIGN KEY (prerequisite_id) REFERENCES public.topics(id);


--
-- Name: active_storage_variant_records fk_rails_993965df05; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_variant_records
    ADD CONSTRAINT fk_rails_993965df05 FOREIGN KEY (blob_id) REFERENCES public.active_storage_blobs(id);


--
-- Name: challenge_answers fk_rails_a3631183be; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.challenge_answers
    ADD CONSTRAINT fk_rails_a3631183be FOREIGN KEY (challenge_question_id) REFERENCES public.challenge_questions(id);


--
-- Name: challenges fk_rails_a528afa02b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.challenges
    ADD CONSTRAINT fk_rails_a528afa02b FOREIGN KEY (winner_id) REFERENCES public.users(id);


--
-- Name: question_reports fk_rails_a926ee914d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.question_reports
    ADD CONSTRAINT fk_rails_a926ee914d FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: assignments fk_rails_aa6b76dac2; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assignments
    ADD CONSTRAINT fk_rails_aa6b76dac2 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: users fk_rails_ab9cdad09e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT fk_rails_ab9cdad09e FOREIGN KEY (managed_by_id) REFERENCES public.users(id);


--
-- Name: classroom_memberships fk_rails_b5f1cb255a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.classroom_memberships
    ADD CONSTRAINT fk_rails_b5f1cb255a FOREIGN KEY (user_id) REFERENCES public.users(id);


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
-- Name: question_reports fk_rails_d3d07540ef; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.question_reports
    ADD CONSTRAINT fk_rails_d3d07540ef FOREIGN KEY (question_id) REFERENCES public.questions(id);


--
-- Name: assignments fk_rails_d4d1665f25; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assignments
    ADD CONSTRAINT fk_rails_d4d1665f25 FOREIGN KEY (homework_id) REFERENCES public.homeworks(id);


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
-- Name: topic_prerequisites fk_rails_e314c27aa4; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.topic_prerequisites
    ADD CONSTRAINT fk_rails_e314c27aa4 FOREIGN KEY (topic_id) REFERENCES public.topics(id);


--
-- Name: skills fk_rails_ee47b87d76; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.skills
    ADD CONSTRAINT fk_rails_ee47b87d76 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: challenge_questions fk_rails_ee55edda04; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.challenge_questions
    ADD CONSTRAINT fk_rails_ee55edda04 FOREIGN KEY (challenge_id) REFERENCES public.challenges(id);


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

\unrestrict sWeQsOdUR3bPj5FcjQYieR20wD6YkkFwrtqklEDVh0S98eG8SlkoYh62NDeWElW

SET search_path TO "$user", public;

INSERT INTO "schema_migrations" (version) VALUES
('20260822152746'),
('20260822000003'),
('20260822000002'),
('20260822000001'),
('20260821000003'),
('20260821000002'),
('20260821000001'),
('20260820000602'),
('20260820000601'),
('20260820000501'),
('20260820000401'),
('20260820000306'),
('20260820000305'),
('20260820000304'),
('20260820000303'),
('20260820000302'),
('20260820000301'),
('20260820000104'),
('20260820000103'),
('20260820000102'),
('20260820000101'),
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

