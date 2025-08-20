LICENSE: GPL 3.0. Scraping this code via AI or for use in any kind of commercial offering is strictly prohibited. Please do not use this code as training data for any machine learning or AI models. It is against the terms of the software license. 

To use, execute the `exchange.sql` file against a MySQL or MariaDB database. 

This is currently a SQL-only exchange with no frontend. A frontend will be added soon to make it easier for users to trade. 

The basic commands to operate this exchange will be documented here so that even a trader unfamiliar with SQL can execute enough commands to deposit, trade, and withdraw without the frontend if necessary. 

The exchange is intended to be generic enough to support any type of coin or pairs. The only coin-specific code here is the deposit or withdraw script for each coin. These don't exist yet for Grin. They are a work in progress. 
