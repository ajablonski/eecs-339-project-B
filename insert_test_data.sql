-- INSERT some users
INSERT INTO users(email, password) VALUES ('bobama@whitehouse.gov', 'test');
INSERT INTO users(email, password) VALUES ('root@root.com', 'rootroot');
INSERT INTO users(email, password) VALUES ('squirrel@groupme.com', 'test');
-- And some sample portfolios
INSERT INTO portfolios(name, owner, cashAccount) VALUES ('Test1', 'root@root.com', 200);
INSERT INTO portfolios(name, owner, cashAccount) VALUES ('Test2', 'root@root.com', 5000);
INSERT INTO portfolios(name, owner, cashAccount) VALUES ('Test3', 'root@root.com', 100);
INSERT INTO portfolios(name, owner, cashAccount) VALUES ('Acorns', 'squirrel@groupme.com', 200.22);
INSERT INTO portfolios(name, owner, cashAccount) VALUES ('Test1', 'squirrel@groupme.com', 300);
