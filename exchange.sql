CREATE TABLE IF NOT EXISTS currencies(
	name varchar(255),
	decimals int not null,
	PRIMARY KEY(name)
);

CREATE TABLE IF NOT EXISTS pairs(
	id INT NOT NULL AUTO_INCREMENT,
	base_currency varchar(255) not null,
	quote_currency varchar(255) not null,
	PRIMARY KEY(id),
	FOREIGN KEY(base_currency) REFERENCES currencies(name),
	FOREIGN KEY(quote_currency) REFERENCES currencies(name),
	UNIQUE(base_currency, quote_currency)
);

CREATE TABLE IF NOT EXISTS balances(
	user CHAR(32),
	currency varchar(255),
	balance INT NOT NULL DEFAULT(0),
	update_timestamp DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
	PRIMARY KEY(user, currency),
	FOREIGN KEY(user) REFERENCES mysql.user(User),
	FOREIGN KEY(currency) REFERENCES currencies(name)
);

CREATE TABLE IF NOT EXISTS orders(
	id INT NOT NULL AUTO_INCREMENT,
	user CHAR(32) NOT NULL,
	pair_id INT NOT NULL,
	base_quantity INT NOT NULL,
	quote_quantity INT NOT NULL,
	side ENUM('buy','sell') NOT NULL,
	insert_timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
	update_timestamp DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP NOT NULL,
	PRIMARY KEY (id),
	FOREIGN KEY(pair_id) REFERENCES pairs(id),
	FOREIGN KEY(user) REFERENCES mysql.user(User),
);
CREATE INDEX order_prices ON orders(base_quantity / quote_quantity);

CREATE TABLE IF NOT EXISTS fills(
	id INT NOT NULL AUTO_INCREMENT,
	taker_order_id INT NOT NULL,
	maker_order_id INT NOT NULL,
	base_quantity INT NOT NULL,
	quote_quantity INT NOT NULL,
	filled_base_quantity INT NOT NULL,
	insert_timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
	update_timestamp DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP NOT NULL,
	PRIMARY KEY(id),
	FOREIGN KEY(taker_order_id) REFERENCES orders(id),
	FOREIGN KEY(maker_order_id) REFERENCES orders(id)
);

CREATE FUNCTION submit_order_buy(pair_id INT, base_quantity INT, quote_quantity INT)
RETURNS TABLE
BEGIN
	CREATE TEMPORARY TABLE maker_orders
	SELECT * FROM orders WHERE pair_id=pair_id AND side='sell' AND filled_base_quantity != base_quantity
	ORDER BY (base_quantity / quote_quantity) ASC;

	
END
