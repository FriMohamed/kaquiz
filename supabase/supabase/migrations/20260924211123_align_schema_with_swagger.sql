-- ============================================================
-- Migration: Align Database Schema with Swagger Specification
-- ============================================================

drop table if exists public.locations cascade;
drop table if exists public.friendships cascade;
drop table if exists public.friend_requests cascade;
drop table if exists public.users cascade;

drop type if exists public.friend_request_status cascade;

-- ============================================================
-- Users Table
-- ============================================================
create table public.users (
    id bigint primary key generated always as identity,

    google_id text not null constraint users_google_id_unique unique,
    email text not null constraint users_email_unique unique,
    name text not null,
    avatar_url text,

    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),

    constraint users_email_lowercase check (email = lower(email)),
    constraint users_name_not_empty check (length(trim(name)) > 0)
);

-- ============================================================
-- Friend Requests Table
-- ============================================================
create type public.friend_request_status as enum (
    'pending',
    'accepted',
    'declined'
);

create table public.friend_requests (
    id bigint primary key generated always as identity,

    sender_id bigint not null
        references public.users(id)
        on delete cascade,

    receiver_id bigint not null
        references public.users(id)
        on delete cascade,

    status public.friend_request_status not null default 'pending',

    created_at timestamptz not null default now(),

    constraint friend_request_not_self
        check (sender_id <> receiver_id)
);

-- Prevent multiple pending requests in the same direction
create unique index friend_requests_pending_unique
on public.friend_requests (sender_id, receiver_id)
where status = 'pending';

-- ============================================================
-- Friendships Table
-- ============================================================
create table public.friendships (
    id bigint primary key generated always as identity,

    user_id bigint not null
        references public.users(id)
        on delete cascade,

    friend_id bigint not null
        references public.users(id)
        on delete cascade,

    created_at timestamptz not null default now(),

    constraint friendship_not_self
        check (user_id <> friend_id)
);

-- Prevent duplicate friendship pairs (A -> B or B -> A)
create unique index friendships_pair_unique
on public.friendships (
    least(user_id, friend_id),
    greatest(user_id, friend_id)
);

-- ============================================================
-- Locations Table
-- ============================================================
create table public.locations (
    user_id bigint primary key
        references public.users(id)
        on delete cascade,

    latitude double precision not null,
    longitude double precision not null,
    accuracy double precision,

    updated_at timestamptz not null default now(),

    constraint locations_latitude_valid
        check (latitude >= -90 and latitude <= 90),

    constraint locations_longitude_valid
        check (longitude >= -180 and longitude <= 180),

    constraint locations_accuracy_valid
        check (accuracy is null or accuracy >= 0)
);

-- ============================================================
-- Indexes
-- ============================================================
create index friend_requests_receiver_idx on public.friend_requests (receiver_id);
create index friend_requests_sender_idx on public.friend_requests (sender_id);
create index friendships_user_idx on public.friendships (user_id);
create index friendships_friend_idx on public.friendships (friend_id);
create index users_google_id_idx on public.users (google_id);