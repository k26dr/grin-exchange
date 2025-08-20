LICENSE: GPL 3.0. Commerical use of MySQL requires a GPL license, so we chose that over MIT License. 

To use, execute the `exchange.sql` file against a MySQL or MariaDB database. 

This is currently a SQL-only exchange with no frontend. A frontend will be added soon to make it easier for users to trade. 

The basic commands to operate this exchange will be documented here so that even a trader unfamiliar with SQL can execute enough commands to deposit, trade, and withdraw without the frontend if necessary. 

The exchange is intended to be generic enough to support any type of coin or pairs. The only coin-specific code here is the deposit or withdraw script for each coin. These don't exist yet for Grin. They are a work in progress. 
