-- ============================================================
-- Migration: Simplify Friend Requests
-- ============================================================

-- Remove the old pending-request index
drop index if exists public.friend_requests_pending_unique;

-- Remove the status column
alter table public.friend_requests
drop column if exists status;

-- Remove the old status enum
drop type if exists public.friend_request_status;

-- Prevent duplicate pending requests in either direction
create unique index friend_requests_pair_unique
on public.friend_requests (
    least(sender_id, receiver_id),
    greatest(sender_id, receiver_id)
);