CREATE TABLE users (
    email varchar(100) not null primary key,
    password varchar(64) not null,
    validation_code int
);

CREATE TABLE portfolios (
    owner varchar(100) not null references users(email),
    id int not null primary key,
    cashAccount number(10, 2) not null --http://w2.syronex.com/jmr/edu/db/introduction-to-oracle/ this is suggested currency for oracle sql
);

-- individual stock holdings for a specific portfolio
CREATE TABLE holdings (
  portfolioID int references portfolios(id),
  stock char(16) not null references cs339.stockssymbols(SYMBOL),
  numShares int not null CHECK (numShares > 0)
);
-- SQL is fun