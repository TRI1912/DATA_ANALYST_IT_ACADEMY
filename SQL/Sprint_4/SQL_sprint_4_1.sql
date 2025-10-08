-- NIVELL 1 --
-- Exercici 1 --
#DROP DATABASE global_market;
CREATE DATABASE global_market CHARACTER SET utf8mb4;

USE global_market;
CREATE TABLE IF NOT EXISTS dim_companies (
 id_company VARCHAR(20) PRIMARY KEY,
 company_name VARCHAR(100) NOT NULL,
 phone VARCHAR(20),
 email VARCHAR(100),
 country VARCHAR(50),
 website VARCHAR(100)
 );

CREATE TABLE IF NOT EXISTS dim_credit_cards (
    id_credit_card VARCHAR(20) PRIMARY KEY,
    user_id INT NOT NULL,
    iban VARCHAR(34) NOT NULL,
    pan VARCHAR(19) NOT NULL,
    pin VARCHAR(4) NOT NULL,
    cvv VARCHAR(3) NOT NULL,
    track1 VARCHAR(255),
    track2 VARCHAR(255),
    expiring_date VARCHAR(20)
);
# Country debería ser NOT NULL, condicionamos una tabla a este valor

#Taula unificada d'usuaris

CREATE TABLE IF NOT EXISTS dim_user (
    id_user VARCHAR(20) PRIMARY KEY,
	name VARCHAR(100),
    surname VARCHAR(100),
    phone VARCHAR(150),
    email VARCHAR(150),
    birth_date DATE,
    country VARCHAR(150),
    city VARCHAR(150),
    postal_code VARCHAR(100),
    address VARCHAR(255)
   );

 CREATE TABLE IF NOT EXISTS dim_products (
	id_products VARCHAR(20) PRIMARY KEY,
    product_name  VARCHAR(255)  NOT NULL,
    price VARCHAR(10) NOT NULL,
    colour VARCHAR(10),
    weight VARCHAR(10) NOT NULL,
    warehouse_id VARCHAR(12) NOT NULL
    );


CREATE TABLE IF NOT EXISTS fact_transaction (
    id_transaction VARCHAR(255) PRIMARY KEY,
    card_id VARCHAR(20) NOT NULL,
    business_id VARCHAR(255) NOT NULL,
    timestamp DATETIME NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    declined BOOLEAN NOT NULL DEFAULT 0,
    product_ids VARCHAR(100),  -- Ens trobem que aquest ids estan agrupats , no es pot crear directament FK fer taula intermitja
    user_id VARCHAR(20) NOT NULL,
    lat DOUBLE,
    longitude DOUBLE,
	FOREIGN KEY (card_id) REFERENCES dim_credit_cards(id_credit_card),
    FOREIGN KEY (business_id) REFERENCES dim_companies(id_company),
    FOREIGN KEY (user_id) REFERENCES dim_user(id_user)
    );
    


USE global_market;
LOAD DATA INFILE  'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\global_market\\companies.csv'
INTO TABLE dim_companies
FIELDS TERMINATED BY ','  
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;

LOAD DATA INFILE  'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\global_market\\credit_cards.csv'
INTO TABLE dim_credit_cards
FIELDS TERMINATED BY ','  
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(id_credit_card, user_id, iban, pan, pin, cvv, track1, track2, @expiring_date)
SET 
expiring_date = STR_TO_DATE(@expiring_date, '%m/%d/%y');

LOAD DATA INFILE 'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\global_market\\american_users.csv'
INTO TABLE dim_user
FIELDS TERMINATED BY ','  
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(id_user, name, surname, phone, email, @birth_date, country, city, postal_code, address)
SET 
birth_date = STR_TO_DATE(@birth_date, '%b %e, %Y');

LOAD DATA INFILE 'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\global_market\\european_users.csv'
INTO TABLE dim_user
FIELDS TERMINATED BY ','  
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(id_user, name, surname, phone, email, @birth_date, country, city, postal_code, address)
SET 
birth_date = STR_TO_DATE(@birth_date, '%b %e, %Y');

LOAD DATA INFILE  'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\global_market\\products.csv'
INTO TABLE dim_products
FIELDS TERMINATED BY ','  
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

LOAD DATA INFILE  'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\global_market\\transactions.csv'
INTO TABLE fact_transaction
FIELDS TERMINATED BY ';'  
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(id_transaction, card_id, business_id, timestamp, amount, declined, product_ids, user_id, lat, longitude);

-- Exercici 1 --
-- Realitza una subconsulta que mostri tots els usuaris amb més de 80 transaccions utilitzant almenys 2 taules --
SELECT u.id_user
FROM dim_user u 
WHERE (
    SELECT COUNT(ft.id_transaction) 
    FROM fact_transaction ft
    WHERE ft.user_id = u.id_user
) > 80;
# nombre y cuanto pago

-- Exercici 2 --
-- Mostra la mitjana d'amount per IBAN de les targetes de crèdit a la companyia Donec Ltd, utilitza almenys 2 taules--
SELECT c.id_company, cc.iban, ROUND(AVG(ft.amount),2)
FROM fact_transaction ft
LEFT JOIN dim_credit_cards cc ON ft.card_id = cc.id_credit_card
LEFT JOIN dim_companies c ON ft.business_id = c.id_company
WHERE c.company_name = 'Donec Ltd'
GROUP BY cc.iban, c.id_company, cc.id_credit_card;

# agrupar por un id para que sigui unic.
-- NIVELL 2 --
-- EXERCICI 1 --
/* Crea una nova taula que reflecteixi l'estat de les targetes de crèdit basat 
en si les últimes tres transaccions van ser declinades i genera la següent 
consulta: Quantes targetes estan actives? */


use global_market;
CREATE TABLE dim_targetes_estat AS
SELECT
    card_id,
    CASE
        WHEN SUM(CASE WHEN declined = 1 THEN 1 ELSE 0 END) = 3 THEN 'Inactiva'
        ELSE 'Activa'
    END AS estat_targeta
FROM (
    SELECT
        ft.card_id,
        ft.declined,
        ROW_NUMBER() OVER (PARTITION BY ft.card_id ORDER BY ft.timestamp DESC) AS filtra_transacció
    FROM fact_transaction ft
) ultimes_transaccions
WHERE filtra_transacció  <= 3 # se queda amb les tres últimes transaccions de cada targeta.
GROUP BY card_id;

SELECT COUNT(*) AS targetes_actives
FROM dim_targetes_estat
WHERE estat_targeta = 'Activa';


-- NIVELL 3 --
/* Crea una taula amb la qual puguem unir les dades del nou arxiu products.csv amb la base de dades creada, 
tenint en compte que des de transaction tens product_ids. Genera la següent consulta */

CREATE TABLE IF NOT EXISTS fact_transaction_products (  #Taula intermitja per producte i transacció
    id_transaction VARCHAR(255),
    id_products VARCHAR(20),
    PRIMARY KEY (id_transaction, id_products),
    FOREIGN KEY (id_transaction) REFERENCES fact_transaction(id_transaction),
    FOREIGN KEY (id_products) REFERENCES dim_products(id_products)
);
# Desglossar products_ids amb una Json table i omplir taula
INSERT INTO fact_transaction_products (id_transaction, id_products)
SELECT 
    ft.id_transaction,
    TRIM(jst.product_ids) AS id_product
FROM
    fact_transaction ft,
    JSON_TABLE(
        CONCAT('["', REPLACE(ft.product_ids, ',', '","'), '"]'),
        '$[*]' COLUMNS(product_ids VARCHAR(20) PATH '$')
    ) AS jst
WHERE TRIM(jst.product_ids) IN (SELECT id_products FROM dim_products);

#Consultar el numero de vegades
SELECT
    p.id_products,p.product_name,
    COUNT(ftp.id_transaction) AS vegades_venut
FROM
    dim_products p
JOIN
    fact_transaction_products ftp ON p.id_products = ftp.id_products
GROUP BY
    p.id_products, p.product_name
ORDER BY
    vegades_venut DESC;