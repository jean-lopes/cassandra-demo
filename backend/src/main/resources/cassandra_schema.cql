CREATE KEYSPACE IF NOT EXISTS demo WITH replication = {'class':'SimpleStrategy', 'replication_factor' : 1};
USE demo;
CREATE TABLE IF NOT EXISTS boardings (id UUID PRIMARY KEY,shipper text,origin text,destiny text,mileage bigint,category text,weight bigint,collection_date timestamp);
