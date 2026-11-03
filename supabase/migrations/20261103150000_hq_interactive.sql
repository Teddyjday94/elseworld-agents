-- Elsewhere HQ becomes interactive: Thomas closes tasks and leaves notes for agents from the page.
-- Additive only. Every write goes through a function that checks its inputs and logs to ops.activity.

alter table ops.shop_tasks add column if not exists thomas_note text not null default '';

create or replace function ops.shop_task_mark(p_id bigint, p_status text, p_note text default null)
returns text language plpgsql set search_path to '' as $$
declare r ops.shop_tasks%rowtype;
begin
  if p_status not in ('open', 'approved', 'done', 'declined') then raise exception using errcode = '22023', message = 'bad_status'; end if;
  select * into r from ops.shop_tasks where id = p_id for update;
  if not found then raise exception using errcode = '22023', message = 'task_not_found'; end if;
  update ops.shop_tasks set status = p_status,
    thomas_note = coalesce(left(nullif(btrim(p_note), ''), 1000), thomas_note),
    closed_at = case when p_status = 'open' then null else now() end
   where id = p_id;
  insert into ops.activity (agent, action) values ('you',
    case p_status when 'approved' then 'Approved: ' when 'done' then 'Did: ' when 'declined' then 'Said no to: ' else 'Reopened: ' end || left(r.item, 140));
  return p_status;
end $$;

-- Notes from Thomas to one agent. The agent reads open notes on its next run and answers.
create table if not exists ops.shop_notes (
  id          bigserial primary key,
  created_at  timestamptz not null default now(),
  agent       text not null references ops.agents(id),
  note        text not null check (length(note) between 1 and 1000),
  status      text not null default 'open' check (status in ('open', 'answered')),
  answer      text not null default '',
  answered_at timestamptz
);
create index if not exists shop_notes_open_idx on ops.shop_notes (agent) where status = 'open';
alter table ops.shop_notes enable row level security;

create or replace function ops.shop_note_add(p_agent text, p_note text)
returns bigint language plpgsql set search_path to '' as $$
declare v_id bigint; v_name text;
begin
  select name into v_name from ops.agents where id = p_agent;
  if not found then raise exception using errcode = '22023', message = 'agent_not_found'; end if;
  if coalesce(btrim(p_note), '') = '' then raise exception using errcode = '22023', message = 'empty_note'; end if;
  insert into ops.shop_notes (agent, note) values (p_agent, left(btrim(p_note), 1000)) returning id into v_id;
  insert into ops.activity (agent, action) values ('you', 'Note to ' || v_name || ': ' || left(btrim(p_note), 140));
  return v_id;
end $$;
