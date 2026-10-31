-- Elsewhere Supply Co. crew: register the six new agents and add a small approvals queue.
-- Additive only. Lives in the shared ops schema next to the Sidequest crew.

insert into ops.agents (id, ord, name, role, status, schedule, next_run, uses_ai, model_tier, hands_to) values
  ('shopchief',   50, 'Store Chief',       'Daily Elsewhere briefing: sales, traffic, fulfillment, the approval queue and the week''s top 3', 'Ready', 'Not scheduled yet', '', true, 'mechanical', 'Thomas (Elsewhere HQ)'),
  ('growth',      51, 'Growth Marketer',   'Traffic beyond the weekly posts: Pinterest SEO, creators, communities, BFCM and ad plans for approval', 'Ready', 'Not scheduled yet', '', true, 'mechanical', 'Thomas (approvals)'),
  ('cro',         52, 'Conversion Doctor', 'Audits the storefront and funnel and proposes fixes so visitors buy', 'Ready', 'Not scheduled yet', '', true, 'mechanical', 'Thomas (approvals)'),
  ('catalog',     53, 'Catalog Keeper',    'Checks Printify and Shopify stay in sync: unlinked products, duplicates, empty collections, missing images', 'Ready', 'Not scheduled yet', '', true, 'mechanical', 'Product Launcher / Thomas'),
  ('orders',      54, 'Order Desk',        'Watches Shopify and Printify orders, flags stuck ones, drafts customer replies in Gmail', 'Ready', 'Not scheduled yet', '', true, 'mechanical', 'Thomas (Gmail drafts)'),
  ('shopfinance', 55, 'Shop Treasurer',    'Margins per product, offer and ad math, weekly Elsewhere P&L', 'Ready', 'Not scheduled yet', '', true, 'mechanical', 'Thomas (approvals)')
on conflict (id) do nothing;

-- Things an Elsewhere agent wants Thomas to approve or do. Agents insert; Thomas (or Claude on his say-so) closes.
create table if not exists ops.shop_tasks (
  id          bigserial primary key,
  created_at  timestamptz not null default now(),
  agent       text not null references ops.agents(id),
  kind        text not null check (kind in ('approve', 'do', 'fyi')),
  item        text not null check (length(item) between 3 and 300),
  cost        text not null default '',
  priority    smallint not null default 2 check (priority between 1 and 3),
  status      text not null default 'open' check (status in ('open', 'approved', 'done', 'declined')),
  closed_at   timestamptz
);
create index if not exists shop_tasks_open_idx on ops.shop_tasks (priority, created_at) where status = 'open';
alter table ops.shop_tasks enable row level security;
