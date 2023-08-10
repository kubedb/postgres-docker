---

# install sqlcmd tools
# https://learn.microsoft.com/en-us/sql/linux/sql-server-linux-setup-tools?view=sql-server-ver16
# https://stackoverflow.com/a/73443215/244009

# sqlcmd -S host,port -U sa -C

# sqlcmd -S 172.232.18.72,1433 -U sa -C
# Pa55w0rd!

CREATE DATABASE Sales
GO
USE [SALES]
GO
CREATE TABLE TDS([id] [int] NOT NULL, [data] varchar(255) NOT NULL)
GO
INSERT INTO TDS (id, data) VALUES (1,'cat'),(2,'dog'),(3,'horse')
GO
SELECT * from [Sales].[dbo].[TDS]
GO

---
# In Postgres

# k port-forward deploy/pgadmin 8080:80

CREATE DATABASE ramdor;

\c ramdor;
CREATE EXTENSION tds_fdw;
SELECT oid, extname, extversion FROM pg_extension;

CREATE SERVER mssql_svr FOREIGN DATA WRAPPER tds_fdw OPTIONS (servername '172.232.18.72', port '1433', database 'sales', tds_version '7.1');

CREATE USER MAPPING FOR postgres SERVER mssql_svr  OPTIONS (username 'sa', password 'Pa55w0rd!');

CREATE FOREIGN TABLE tds (
 id integer,
 data varchar)
 SERVER mssql_svr
 OPTIONS (query 'SELECT * FROM [Sales].[dbo].[TDS]', row_estimate_method 'showplan_all');
