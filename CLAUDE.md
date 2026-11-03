# Elsewhere Supply Co. — Operations

Shared context for every agent in `.claude/agents/`. Read this first.

## Two crews, one store
Elsewhere Supply Co. belongs to Thomas, who also runs Sidequest Creative. Some Elsewhere work already runs inside the **Sidequest crew** (repo `Teddyjday94/sidequest-commandcenter`). These agents are live there:
- Trend Scout (`trends`): shirt ideas into `ops.shop_ideas`
- Shop Designer: artwork for liked ideas
- Product Launcher (`launcher`): copy, SEO, tags, alt text and collections for new products
- Social Planner (`socialplan`): weekly posts into `ops.shop_posts`
- Blog Writer (`blogger`): one blog post a week
- Monday Brief: counts last week for both businesses

The ideas and posts live on the **Elsewhere Idea Board**: https://claude.ai/artifact/MMqakwJ9ANhygv7aN9rfi4

This repo adds the **Elsewhere crew** for the gaps. Every agent reads the other crew's work and never redoes it:
| Agent | `ops.agents` id | Owns |
|---|---|---|
| Store Chief | `shopchief` | Daily briefing, approval queue, priorities |
| Growth Marketer | `growth` | Traffic beyond weekly posts: Pinterest, creators, campaigns, ad plans |
| Conversion Doctor | `cro` | Storefront and funnel |
| Catalog Keeper | `catalog` | Printify↔Shopify sync and catalog health |
| Order Desk | `orders` | Fulfillment and customer email drafts |
| Shop Treasurer | `shopfinance` | Margins, offer math, P&L |

## The business
- Shopify store: **Elsewhere Supply Co.** (elsewheresupplyco.myshopify.com, internal g05ctr-0g.myshopify.com), Basic plan, USD, US, Central time.
- Model: **print-on-demand apparel** fulfilled by **Printify** (shop id `29509655`). No inventory is held; Printify prints and ships each order. Shopify inventory counts are meaningless placeholders.
- Catalog: tees (Bella+Canvas 3001, blueprint 12), hoodies (Gildan 18500, blueprint 77), hats/beanies/bucket hats. Product lines:
  - **Elsewhere / dry humor**: Currently Elsewhere, Not AI. Just Tired., Do Not Perceive Me, Seasonal Depression World Tour, Ships in 6–7 Business Days, Odysseus Layover
  - **Calm mind** (Drop 002): Systems Still Functional, Same Chaos Different Day, Same Mind Brighter Days, Balance, Somewhere in a Calmer Place, A Quieter Mind
  - **Own Lane** (women's empowerment): In My Own Lane, Butterfly Effect, Lucky Charm, Sunflower Soul, Color Me Bold, Crown & Curls, Pink Crown, Sisterhood
  - **Bookish** (in Printify, NOT yet published to Shopify): Please Respect the Plot, Stacked Books, Skeleton Reading Book, Read Wildly, My Happy Place
- Collections: T-Shirts, Hoodies & Sweatshirts, Hats, Accessories (empty), Drop 001, Drop 002, Own Lane, Home page.

## Unit economics (Printify cost vs retail, checked 2026-10-31)
| Item | Retail | Printify cost | Gross before shipping/fees |
|---|---|---|---|
| Hoodie S–XL | $45 | $30.79 | $14.21 |
| Hoodie 2XL+ | $48 | $33.04 | $14.96 |
| Tee S–XL | $30 | $17.92 | $12.08 |
| Tee 2XL+ | $33 | $20.54 | $12.46 |
Shopify Payments takes about 2.9% + $0.30. Printify shipping (roughly $4–9 per item in the US) comes out of that margin unless the customer pays it. Re-pull live costs from Printify before any pricing decision; never rely on this table alone.

## Baseline (2026-10-31)
- 0 orders all-time. Last 30 days: 85 sessions, 1 add-to-cart, 0 checkouts.
- The store is online: password protection is off and SSL is on.
- Main bottleneck is **traffic**, with conversion second. Every agent should rank its suggestions by how much they move the store toward its first sales.

## Tools available
- **Shopify MCP** (`mcp__Shopify__*`): products, collections, orders, customers, discounts, ShopifyQL analytics, GraphQL read and write.
- **Printify REST API** at `https://api.printify.com/v1/` (the proxy injects auth, so no key is needed). Useful endpoints: `shops/29509655/products.json`, `.../products/{id}.json`, `.../products/{id}/publish.json`, `.../orders.json`, `catalog/blueprints/{id}/print_providers/{pid}/shipping.json`.
- **TikTok for Business MCP**: ad account, catalog, reporting, Smart+ campaigns.
- **Gmail MCP**: customer email (drafts only, see rules).
- **Canva / Artlist / Higgsfield MCPs**: creative assets, mockups, video.
- **Shirt artwork** is made by the Sidequest crew's Shop Designer with **GPT Image 2.5** (ChatGPT's image model) through Artlist. Thomas chose this on 2026-11-03. It needs Artlist credits: the account had 0 that day, and a design costs about 340 credits for 2 versions at 4K. Any agent that suggests new artwork should assume this model and budget.
- `social-media-skills:*` skills for content, captions, and scripts for TikTok, Pinterest, and Instagram.
- Playwright and Chromium for auditing the live storefront.

## Reporting to Elsewhere HQ (every run)
Elsewhere HQ (https://claude.ai/artifact/TaYyCgL2E7uiK7DgjB71iM) is a game view of both crews. It reads Supabase project `taskvfzqgpqxpdifmxru`, schema `ops` (use `mcp__Supabase__execute_sql`). **At the start of each run**, read Thomas's notes to you:
```sql
select id, note, created_at from ops.shop_notes where agent = '<your id>' and status = 'open' order by created_at
```
- Treat each note as a direct instruction from Thomas for this run, within the ground rules.
- When you're done, answer it with `update ops.shop_notes set status = 'answered', answer = '<2 to 4 plain sentences: what you did or found>', answered_at = now() where id = <id>`.
- The answer shows up in his chat with you on Elsewhere HQ.

Also read the quests he closed since your last run: `ops.shop_tasks` rows with `status in ('approved', 'declined', 'done')` and a recent `closed_at`. Read his `thomas_note` on each, and act on what he approved.

At the end of each run:
1. Update your row in `ops.agents` with `last_run = current_date`, `last_result = '<one plain sentence>'`, and `next_run = '<when>'`.
2. Add one row to `ops.activity (agent, action)`, using your display name and one sentence on what you did.
3. Queue anything for Thomas in `ops.shop_tasks (agent, kind, item, cost, priority)`:
   - `kind` is `approve` for decisions, `do` for clicks only he can make, `fyi` for notes.
   - `priority` 1 means this week.
   - Before inserting, check for an open row with the same meaning.
   - Close rows you've resolved by setting `status = 'done'` and `closed_at = now()`.
4. Interactive runs: write your report file in `reports/`. Scheduled runs work from a read-only clone, so they skip the file; `ops` and the run's final message are the record.

Touch only the `ops` schema, and never `public`, which is Thomas's live client portal. Don't write to Sidequest tables such as leads or todos.

## Ground rules (all agents)
1. **Spending money needs the owner's approval.** Never launch or raise an ad budget, buy apps, domains, or samples, or place orders without explicit approval in the current conversation.
2. **Agents never create, edit, publish, price or discount anything in the store on their own.** This matches the Sidequest hard rule. Propose changes in `ops.shop_tasks`. Apply one only when Thomas says yes in the current conversation. Listing copy and SEO stay with the Product Launcher.
3. **Email: create Gmail drafts, never send.**
4. **Never delete** products, collections, or customer data. Archive or propose instead.
5. **Use live data.** Pull numbers from Shopify or Printify each run; never quote from memory. If a number can't be fetched, say so.
6. Write each run's output to `reports/YYYY-MM-DD-<agent>.md`, with the top 3 recommended actions and their expected impact at the top.
7. Stay honest in marketing: no fake reviews, fake scarcity, or invented stats. Copy has no em dashes and no AI-sounding phrasing. The tone is dry, kind and a little tired, like the shirts. Keep in mind that POD shipping takes about 6–10 business days.
8. No secrets in this repo: no API keys, tokens or `.env` files. Connections come from Claude connectors and the proxy.
