CREATE TABLE currencies(
	name varchar(255),
	decimals int not null,
	PRIMARY KEY(name)
);

CREATE TABLE pairs(
	base_currency varchar(255) not null,
	quote_currency varchar(255) not null,
	PRIMARY KEY(base_currency, quote_currency),
	FOREIGN KEY(base_currency) REFERENCES currencies(name),
	FOREIGN KEY(quote_currency) REFERENCES currencies(name)
);

CREATE TABLE balances(
	user CHAR(32),
	currency varchar(255),
	balance INT NOT NULL DEFAULT(0),
	PRIMARY KEY(user, currency)
);
