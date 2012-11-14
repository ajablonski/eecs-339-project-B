-- INSERT some users
INSERT INTO users(email, password) VALUES ('bobama@whitehouse.gov', 'test');
INSERT INTO users(email, password) VALUES ('root@root.com', 'rootroot');
INSERT INTO users(email, password) VALUES ('squirrel@groupme.com', 'test');
-- And some sample portfolios
INSERT INTO portfolios(name, owner, cashAccount) VALUES ('Tech', 'root@root.com', 200.20);
INSERT INTO portfolios(name, owner, cashAccount) VALUES ('Air', 'root@root.com', 5000.50);
INSERT INTO portfolios(name, owner, cashAccount) VALUES ('Money', 'root@root.com', 100.10);
INSERT INTO portfolios(name, owner, cashAccount) VALUES ('Diverse', 'root@root.com', 19.92);
INSERT INTO portfolios(name, owner, cashAccount) VALUES ('Acorns', 'squirrel@groupme.com', 200.22);
INSERT INTO portfolios(name, owner, cashAccount) VALUES ('Test1', 'squirrel@groupme.com', 300);
-- Get root's Test1 account ID;
VAR portID number;
BEGIN
    SELECT id INTO :portID FROM portfolios WHERE name='Tech' AND owner='root@root.com';
END;
/

INSERT INTO holdings(portfolioID, stock, numShares) VALUES (:portID, 'AAPL', 20);
INSERT INTO holdings(portfolioID, stock, numShares) VALUES (:portID, 'MSFT', 200);
INSERT INTO holdings(portfolioID, stock, numShares) VALUES (:portID, 'GOOG', 50);
INSERT INTO holdings(portfolioID, stock, numShares) VALUES (:portID, 'AMZN', 75);
BEGIN
    SELECT id INTO :portID FROM portfolios WHERE name='Air' AND owner='root@root.com';
END;
/

INSERT INTO holdings(portfolioID, stock, numShares) VALUES (:portID, 'LUV', 100);
INSERT INTO holdings(portfolioID, stock, numShares) VALUES (:portID, 'JBLU', 75);
INSERT INTO holdings(portfolioID, stock, numShares) VALUES (:portID, 'DAL', 60);
INSERT INTO holdings(portfolioID, stock, numShares) VALUES (:portID, 'UAL', 92);
INSERT INTO holdings(portfolioID, stock, numShares) VALUES (:portID, 'LCC', 15);
BEGIN
    SELECT id INTO :portID FROM portfolios WHERE name='Money' AND owner='root@root.com';
END;
/

INSERT INTO holdings(portfolioID, stock, numShares) VALUES (:portID, 'BAC', 20);
INSERT INTO holdings(portfolioID, stock, numShares) VALUES (:portID, 'JPM', 90);
INSERT INTO holdings(portfolioID, stock, numShares) VALUES (:portID, 'AXP', 19);
INSERT INTO holdings(portfolioID, stock, numShares) VALUES (:portID, 'V', 30);
INSERT INTO holdings(portfolioID, stock, numShares) VALUES (:portID, 'MA', 40);
INSERT INTO holdings(portfolioID, stock, numShares) VALUES (:portID, 'C', 10);
BEGIN
    SELECT id INTO :portID FROM portfolios WHERE name='Diverse' AND owner='root@root.com';
END;
/

INSERT INTO holdings(portfolioID, stock, numShares) VALUES (:portID, 'BAC', 30);
INSERT INTO holdings(portfolioID, stock, numShares) VALUES (:portID, 'DAL', 22);
INSERT INTO holdings(portfolioID, stock, numShares) VALUES (:portID, 'CAG', 19);
INSERT INTO holdings(portfolioID, stock, numShares) VALUES (:portID, 'XOM', 100);
INSERT INTO holdings(portfolioID, stock, numShares) VALUES (:portID, 'MSFT', 30);
INSERT INTO holdings(portfolioID, stock, numShares) VALUES (:portID, 'TM', 66);
INSERT INTO holdings(portfolioID, stock, numShares) VALUES (:portID, 'PFE', 53);
INSERT INTO holdings(portfolioID, stock, numShares) VALUES (:portID, 'T', 30);
INSERT INTO holdings(portfolioID, stock, numShares) VALUES (:portID, 'KO', 70);
