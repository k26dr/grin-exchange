SET sql_safe_updates = 1;

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
	user CHAR(32) NOT NULL,
	currency varchar(255) NOT NULL,
	balance NUMERIC(32,18) NOT NULL DEFAULT(0),
	insert_timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
	update_timestamp DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
	PRIMARY KEY(user, currency),
	FOREIGN KEY(user) REFERENCES mysql.user(User),
	FOREIGN KEY(currency) REFERENCES currencies(name)
);

CREATE TABLE IF NOT EXISTS orders(
	id INT NOT NULL AUTO_INCREMENT,
	user CHAR(32) NOT NULL,
	pair_id INT NOT NULL,
	base_quantity NUMERIC(32,18) NOT NULL,
	quote_quantity NUMERIC(32,18) NOT NULL,
	filled_base_quantity INT DEFAULT 0,
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
	base_quantity NUMERIC(32,18) NOT NULL,
	quote_quantity NUMERIC(32,18) NOT NULL,
	insert_timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
	update_timestamp DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP NOT NULL,
	PRIMARY KEY(id),
	FOREIGN KEY(taker_order_id) REFERENCES orders(id),
	FOREIGN KEY(maker_order_id) REFERENCES orders(id)
);

CREATE TABLE IF NOT EXISTS settlements(
	id INT NOT NULL AUTO_INCREMENT,
	user CHAR(32) NOT NULL,
	currency varchar(255) NOT NULL,
	direction ENUM('deposit', 'withdraw') NOT NULL,
	amount NUMERIC(32,18) NOT NULL,
	status ENUM('pending', 'fulfilled', 'canceled') NOT NULL DEFAULT 'pending',
	txid varchar(255),
	PRIMARY KEY(id),
	FOREIGN KEY(user) REFERENCES mysql.user(User),
	FOREIGN KEY(currency) REFERENCES currencies(name),
	UNIQUE(txid)
);

CREATE PROCEDURE submit_order(pair_id INT, side ENUM('buy', 'sell'), base_quantity NUMERIC(32,18), quote_quantity NUMERIC(32,18))
RETURNS TABLE
BEGIN
	DECLARE maker_side ENUM('buy', 'sell') DEFAULT CASE WHEN side = 'buy' THEN 'sell' ELSE 'buy';
	DECLARE order_id INT DEFAULT
	INSERT INTO orders (user, pair_id, base_quantity, quote_quantity, side) VALUES (USER(), pair_id, base_quantity, quote_quantity);

	CREATE TEMPORARY TABLE unsorted_maker_orders
	SELECT * FROM orders WHERE pair_id=pair_id AND side=maker_side AND filled_base_quantity != base_quantity

	CREATE TEMPORARY TABLE sorted_maker_orders IF(
		maker_side = 'buy', 
		SELECT * FROM unsorted_maker_orders ORDER BY (base_quantity / quote_quantity) DESC,
		SELECT * FROM unsorted_maker_orders ORDER BY (base_quantity / quote_quantity) ASC,
	);

	DECLARE fill_qty NUMERIC(32,18) DEFAULT 0;
	DECLARE counter INT DEFAULT 0;
	DECLARE num_maker_orders INT DEFAULT SELECT COUNT(*) FROM sorted_maker_orders;
	WHILE fill_qty < base_quantity AND counter < num_maker_orders DO
		CREATE TEMPORARY TABLE order_entry SELECT * FROM sorted_maker_orders OFFSET counter LIMIT 1;
		DECLARE filled_base_quantity DEFAULT SELECT MIN(order_entry.base_quantity - order_entry.filled_base_quantity, base_quantity - fill_qty);
		DECLARE filled_quote_quantity NUMERIC(32,18) DEFAULT (filled_base_quantity / order_entry.base_quantity * order_entry.quote_quantity);
		SET fill_qty = fill_qty + filled_base_quantity;
		UPDATE orders SET filled_base_quantity = filled_base_quantity + fill_qty WHERE id=order_entry.id;
		INSERT INTO fills(taker_order_id, maker_order_id, base_quantity, quote_quantity) VALUES (order_id, order_entry.id, filled_base_quantity, filled_quote_quantity);
		SET counter = counter + 1;
	END WHILE;

	UPDATE orders SET filled_base_quantity = fill_qty WHERE id=order_id;	
	RETURN SELECT * FROM orders WHERE id=order_id;
END

CREATE PROCEDURE show_balances()
RETURNS TABLE
BEGIN
	RETURN SELECT * FROM balances WHERE user=USER();
END

CREATE PROCEDURE my_orders()
RETURNS TABLE
BEGIN
	RETURN SELECT * FROM orders WHERE user=USER();
END

CREATE PROCEDURE view_orderbook(pair_id INT, side ENUM('buy','sell'))
RETURNS TABLE
BEGIN
	CREATE TEMPORARY TABLE unsorted_orders SELECT * FROM orders WHERE pair_id=pair_id;
	RETURN IF(
		side = 'buy', 
		SELECT * FROM unsorted_orders ORDER BY (base_quantity / quote_quantity) DESC,
		SELECT * FROM unsorted_orders ORDER BY (base_quantity / quote_quantity) ASC,
	);
END

CREATE PROCEDURE create_balances(user varchar(255))
RETURNS 'OK'
BEGIN
	INSERT INTO balances (user, currency, balance) VALUES (USER(), 'GRIN', 0);
	INSERT INTO balances (user, currency, balance) VALUES (USER(), 'USDC', 0);
END

CREATE PROCEDURE create_deposit(user varchar(255), currency varchar(255), amount NUMERIC(32,18), txid varchar(255))
RETURNS 'OK'
BEGIN
	UPDATE balances SET balance=balance + amount WHERE user=user AND currency=currency;
	INSERT INTO settlements ('user', 'currency', 'amount', 'direction', 'txid') VALUES (USER(), currency, amount, 'deposit', txid);
END

CREATE PROCEDURE request_withdraw(currency varchar(255), amount NUMERIC(32,18))
RETURNS 'OK'
BEGIN
	UPDATE balances SET balance=balance - amount WHERE user=USER() AND currency=currency;
	INSERT INTO settlements ('user', 'currency', 'amount', 'direction') VALUES (USER(), currency, amount, 'withdraw');
END

-- Role administration

CREATE ROLE customer, settler, admin;

GRANT EXECUTE ON create_balances, create_deposit to settler;
GRANT UPDATE ON settlements to settler;
GRANT EXECUTE ON submit_order to customer;
GRANT EXECUTE ON show_balances to customer;
GRANT EXECUTE ON view_orderbook to customer;
GRANT EXECUTE ON request_withdraw to customer;
