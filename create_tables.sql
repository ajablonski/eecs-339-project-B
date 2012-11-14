CREATE TABLE users (
    email varchar(100) NOT NULL PRIMARY KEY,
    password varchar(64) NOT NULL,
    validation_code int
);

CREATE TABLE portfolios (
    owner varchar(100) NOT NULL REFERENCES users(email),
    id int NOT NULL PRIMARY KEY,
    cashAccount number(10, 2) NOT NULL, --w2.syronex.com/jmr/edu/db/introduction-to-oracle/ this is suggested currency for oracle sql
    name varchar(100),
    UNIQUE (owner, name),
    CONSTRAINT no_nonzero_cash_balance CHECK (cashAccount >= 0)
);

-- individual stock holdings for a specific portfolio
CREATE TABLE holdings (
  portfolioID int REFERENCES portfolios(id) ON DELETE CASCADE,
  stock char(16) NOT NULL REFERENCES cs339.stockssymbols(symbol),
  numShares int NOT NULL CHECK (numShares > 0),
  UNIQUE(portfolioID, stock)
);

CREATE SEQUENCE portfolioID;

CREATE OR REPLACE TRIGGER generatePortfolioID
    BEFORE INSERT ON portfolios
    FOR EACH ROW
    BEGIN
        :new.id := portfolioID.NEXTVAL;
    END;
/


