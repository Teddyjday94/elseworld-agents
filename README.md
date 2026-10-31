# Elsewhere Supply Co. crew

This is the agent crew that runs Elsewhere Supply Co., a print-on-demand apparel store on Shopify. Printify prints and ships each order.

**Elsewhere HQ** is a game view of the crew, in the same Aether Archipelago art as Sidequest HQ: https://claude.ai/artifact/TaYyCgL2E7uiK7DgjB71iM

## Two crews, one store
Some Elsewhere work already runs inside the **Sidequest crew** (`Teddyjday94/sidequest-commandcenter`):
- **Trend Scout and Shop Designer** come up with shirt ideas and artwork.
- **Product Launcher** finishes new listings.
- **Social Planner** writes the weekly posts.
- **Blog Writer** publishes one post a week.

This repo adds six agents to cover the gaps:

| Agent | File | Owns |
|---|---|---|
| Store Chief | `.claude/agents/store-chief.md` | Daily briefing, the approval queue, the week's top 3 |
| Growth Marketer | `.claude/agents/growth-marketer.md` | Traffic beyond weekly posts: Pinterest, creators, BFCM, ad plans |
| Conversion Doctor | `.claude/agents/conversion-doctor.md` | Storefront and funnel audit, offers |
| Catalog Keeper | `.claude/agents/catalog-keeper.md` | Printify↔Shopify sync, duplicates, empty collections |
| Order Desk | `.claude/agents/order-desk.md` | Fulfillment watch and customer email drafts |
| Shop Treasurer | `.claude/agents/shop-treasurer.md` | Margins, offer and ad math, P&L |

`CLAUDE.md` holds the shared business facts, unit economics, reporting steps and hard rules. Every agent reads it first.

## How they report
Each run writes to Supabase project `taskvfzqgpqxpdifmxru`, schema `ops`, which is the same database as the Sidequest crew:
- `ops.agents`: the agent's last run and result
- `ops.activity`: one line on what it did
- `ops.shop_tasks`: anything Thomas needs to approve or do

Agents also save a report file in `reports/`. Elsewhere HQ reads `ops` through the Supabase connector and the store through the Shopify connector. It refreshes every 90 seconds and never writes anything.

## Hard rules
- Agents never create, edit, publish, price or discount anything in the store on their own. They queue it in `ops.shop_tasks`.
- No money is spent without Thomas's yes.
- Gmail: drafts only.
- Touch only the `ops` schema, never `public`.

## Repo layout
```
CLAUDE.md                     shared context and rules for every agent
.claude/agents/*.md           the six agents
supabase/migrations/          ops.agents rows and the ops.shop_tasks table
hq/index.html, hq/assets/     Elsewhere HQ (republish with the Artifact tool, same URL, assets as files)
reports/                      run reports
```

## Using them
Open Claude Code in this repo and ask in plain words, for example:
- "Store Chief, give me today's briefing"
- "Have the Catalog Keeper check the store"
- "Shop Treasurer, what should our Black Friday offer be?"

They aren't on a schedule yet. Ask Claude to set them up as scheduled tasks when you're ready.
