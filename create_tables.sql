CREATE TABLE users (
    email varchar(100) not null primary key,
    password varchar(64) not null,
    validation_code int
);
