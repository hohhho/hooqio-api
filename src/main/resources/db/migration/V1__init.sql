create table users (
  id bigserial primary key,
  email varchar(255) not null unique,
  username varchar(50) not null unique,
  password_hash varchar(255) not null,
  role varchar(20) not null default 'USER',
  status varchar(20) not null default 'ACTIVE',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  last_login_at timestamptz
);

create index idx_users_created_at on users(created_at desc);

create table posts (
  id bigserial primary key,
  author_id bigint not null references users(id),
  title varchar(200) not null,
  content text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create index idx_posts_created_at_id on posts(created_at desc, id desc);
create index idx_posts_author_created_at on posts(author_id, created_at desc);

create table refresh_tokens (
  id bigserial primary key,
  user_id bigint not null references users(id),
  token_hash varchar(255) not null,
  expires_at timestamptz not null,
  revoked_at timestamptz,
  created_at timestamptz not null default now()
);

create unique index uq_refresh_tokens_token_hash on refresh_tokens(token_hash);
create index idx_refresh_tokens_user_id on refresh_tokens(user_id);
create index idx_refresh_tokens_expires_at on refresh_tokens(expires_at);
