-- NIVELL_1 --
-- EXERCICI_1 --

USE transactions;
CREATE TABLE company (id INT PRIMARY KEY,
 company_name VARCHAR(100) NOT NULL,
 phone VARCHAR(20),
 email VARCHAR(100),
 country VARCHAR(50),
website VARCHAR(100));
CREATE TABLE transaction (
    id INT PRIMARY KEY,
    credit_card_id INT NOT NULL,
    company_id INT NOT NULL,
    user_id INT NOT NULL,
    lat DECIMAL(9,6),
    longitude DECIMAL(9,6),
    timestamp DATETIME NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    declined BOOLEAN NOT NULL
);
DROP TABLE IF EXISTS transactions;

-- EXERCICI_2 --
-- Llistar els països que estan generant vendes --

SELECT DISTINCT c.country
FROM transaction t
JOIN company c ON t.company_id = c.id 
WHERE t.declined = FALSE # busco els països on l'empresa té al menys una transacció aprovada
ORDER BY country ASC;

-- Des de quants països es generen les vendes --
/*Fem servir un WHERE t.declined =FALSE en l'exercici anterior ja hem vist que son 15 països, però es fa un codi per
fer servir la funció COUNT*/

SELECT COUNT(DISTINCT c.country) AS total_paisos # Compte els països distints usats
FROM transaction t
JOIN company c ON t.company_id = c.id
WHERE t.declined = FALSE;

-- Identifica la companyia amb la mitjana més gran de vendes --
SELECT 
    c.company_name, 
    ROUND(AVG(t.amount), 2) AS mitjana_vendes
FROM transaction t
JOIN company c ON t.company_id = c.id
WHERE t.declined = FALSE
GROUP BY c.company_name
ORDER BY mitjana_vendes DESC
LIMIT 1;

-- EXERCICI_3 --
-- Mostra totes les transaccions realitzades per empreses d'Alemanya --
SELECT company_id, id
FROM transaction t
WHERE (
    SELECT country
    FROM company c
    WHERE c.id = t.company_id
) = 'Germany';

-- Llista les empreses que han realitzat transaccions per un amount superior a la mitjana de totes les transaccions --
# Llista de le empreses i la quantitat de les seves transacions que superant la mitja de totes les transacions
SELECT DISTINCT c.company_name, t.amount
FROM company c, transaction t # enllaç de la empresa amb la seva transacció
WHERE c.id = t.company_id
  AND t.amount > (SELECT AVG(amount) FROM transaction); # Filtre per obtenirvalors més grans que la mitja global.

/*estic dudosa i no sé si es vol la Suma total per empresa de les que superan la mitja global. Sería una altre forma suma totes les transaccions
i fer la mitjana i obtenir les empreses amb vendes per la suma total de la mitjana. */
SELECT c.company_name, SUM(t.amount) AS total_amount
FROM company c, transaction t
WHERE c.id = t.company_id
  AND t.amount > (SELECT AVG(amount) FROM transaction)
GROUP BY c.company_name;

-- Eliminaran del sistema les empreses que no tenen transaccions registrades, entrega el llistat d'aquestes empreses --
# Llista de les empreses sense cap transacció.
SELECT *
FROM company c
WHERE NOT EXISTS (
    SELECT 1 # Per no portar totes les columnes, es fa servir el SELECT 1 per conèixer si existeix al menys un registre
    FROM transaction t
    WHERE t.company_id = c.id
);

# No hi ha cap empresa sense transacció, cap valor perdut o null. S'ha tingut en compte tant transaccions aprovadades com no aprovadades

DELETE FROM company c
WHERE NOT EXISTS (
    SELECT 1
    FROM transaction t
    WHERE t.company_id = c.id
);

-- NIVELL_2--
-- EXERCICI 1--
/* Identifica els cinc dies que es va generar la quantitat més gran d'ingressos a l'empresa per vendes. 
Mostra la data de cada transacció juntament amb el total de les vendes */

SELECT SUM(t.amount) AS total_de_ventas, DATE(t.timestamp) AS data
FROM transaction t
WHERE t.declined = FALSE
GROUP BY DATE(t.timestamp) # Es fa servir timestamp per treure nomes la part de la data.
ORDER BY total_de_ventas DESC
LIMIT 5;

-- EXERCICI 2 --
-- Quina és la mitjana de vendes per país? Presenta els resultats ordenats de major a menor mitjà--

SELECT c.country, ROUND(AVG(t.amount), 2) AS mitjana_vendes
FROM transaction t
JOIN company c ON t.company_id = c.id
WHERE t.declined = FALSE
GROUP BY c.country
ORDER BY mitjana_vendes DESC;

-- EXERCICI 3 --
/* En la teva empresa, es planteja un nou projecte per a llançar algunes campanyes publicitàries per a fer competència
 a la companyia "Non Institute". Per a això, et demanen la llista de totes les transaccions realitzades per empreses 
 que estan situades en el mateix país que aquesta companyia.*/

-- Mostra el llistat aplicant JOIN i subconsultes. --
SELECT *
FROM transaction t
JOIN company c ON t.company_id = c.id
WHERE declined = FALSE and c.country = (
    SELECT country 
    FROM company 
    WHERE company_name = 'Non Institute'
)

-- Mostra el llistat aplicant solament subconsultes.--

SELECT *
FROM transaction
WHERE declined = FALSE AND company_id IN (
    SELECT id
    FROM company
    WHERE country = (
        SELECT country 
        FROM company 
        WHERE company_name = 'Non Institute')
    );

-- NIVELL_3 --
-- Exercici 1-- 
/* Presenta el nom, telèfon, país, data i amount, d'aquelles empreses que van realitzar transaccions amb un 
valor comprès entre 350 i 400 euros i en alguna d'aquestes dates: 29 d'abril del 2015, 20 de juliol del 2018 i 13 de març del 2024. 
Ordena els resultats de major a menor quantitat. */

SELECT 
    c.company_name, 
    c.phone, 
    c.country, 
    DATE(t.timestamp) AS transaction_date, 
    t.amount
FROM 
    company c
JOIN 
    transaction t ON t.company_id = c.id
WHERE 
    DATE(t.timestamp) IN ('2015-04-29', '2018-04-20', '2024-03-13')
    AND t.amount BETWEEN 350 AND 400
    ORDER BY amount DESC;
    
/* Necessitem optimitzar l'assignació dels recursos i dependrà de la capacitat operativa que es requereixi, 
per la qual cosa et demanen la informació sobre la quantitat de transaccions que realitzen les empreses, 
però el departament de recursos humans és exigent 
i vol un llistat de les empreses on especifiquis si tenen més de 400 transaccions o menys.*/
SELECT 
    c.company_name,
    COUNT(t.id) AS total_transactions,
    CASE 
        WHEN COUNT(t.id) > 400 THEN 'Más de 400'
        ELSE '400 o menos'
    END AS categoria
FROM company c
LEFT JOIN transaction t 
    ON c.id = t.company_id
GROUP BY c.company_name
ORDER BY total_transactions DESC;

