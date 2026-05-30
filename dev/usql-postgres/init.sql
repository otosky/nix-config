create table if not exists widgets (
  id integer generated always as identity primary key,
  name text not null,
  category text not null,
  status text not null,
  sku text not null,
  description text not null,
  notes text not null,
  created_at timestamptz not null default now()
);

insert into widgets (name, category, status, sku, description, notes)
values
  (
    'alpha',
    'laboratory-instrumentation',
    'available-for-wide-output-testing',
    'ALPHA-POSTGRES-USQL-000001',
    'A deliberately verbose widget description used to test whether usql output opens in a pager or wraps inside the terminal pane.',
    'This row should be wide enough to make narrow Neovim terminal splits uncomfortable without horizontal scrolling or pager support.'
  ),
  (
    'beta',
    'observability-and-analytics',
    'pending-review-for-display-regression-checks',
    'BETA-POSTGRES-USQL-000002',
    'Another intentionally long text column so select-star queries produce wide tabular output for REPL display experiments.',
    'Use this sample data to compare pspg behavior, terminal wrapping, and Neovim split sizing when sending SQL through Iron.'
  )
on conflict do nothing;
