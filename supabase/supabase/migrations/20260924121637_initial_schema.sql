-- ============================================================
-- Users
-- ============================================================

create table public.users (
    id uuid primary key default gen_random_uuid(),

    email text not null,
    password_hash text,

    name text not null,
    avatar_url text,

    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),

    constraint users_email_unique unique (email),
    constraint users_email_lowercase check (email = lower(email)),
    constraint users_name_not_empty check (length(trim(name)) > 0)
);


-- ============================================================
-- Friend Requests
-- ============================================================

create type public.friend_request_status as enum (
    'pending',
    'accepted',
    'declined'
);

create table public.friend_requests (
    id uuid primary key default gen_random_uuid(),

    sender_id uuid not null
        references public.users(id)
        on delete cascade,

    receiver_id uuid not null
        references public.users(id)
        on delete cascade,

    status public.friend_request_status not null default 'pending',

    created_at timestamptz not null default now(),

    constraint friend_request_not_self
        check (sender_id <> receiver_id)
);


-- Only one pending request in the same direction.
create unique index friend_requests_pending_unique
on public.friend_requests (sender_id, receiver_id)
where status = 'pending';


-- ============================================================
-- Friendships
-- ============================================================

create table public.friendships (
    id uuid primary key default gen_random_uuid(),

    user_id uuid not null
        references public.users(id)
        on delete cascade,

    friend_id uuid not null
        references public.users(id)
        on delete cascade,

    created_at timestamptz not null default now(),

    constraint friendship_not_self
        check (user_id <> friend_id)
);


-- Prevent A -> B from existing twice.
create unique index friendships_pair_unique
on public.friendships (
    least(user_id, friend_id),
    greatest(user_id, friend_id)
);


-- ============================================================
-- Last Known Locations
-- ============================================================

create table public.locations (
    user_id uuid primary key
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

create index friend_requests_receiver_idx
on public.friend_requests (receiver_id);

create index friend_requests_sender_idx
on public.friend_requests (sender_id);

create index friendships_user_idx
on public.friendships (user_id);

create index friendships_friend_idx
on public.friendships (friend_id);