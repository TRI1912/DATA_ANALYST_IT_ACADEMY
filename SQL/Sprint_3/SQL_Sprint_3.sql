-- SPRINT_3 --
-- NIVELL 1 --
/* Exercici 1 : La teva tasca és dissenyar i crear una taula anomenada "credit_card" que emmagatzemi detalls 
crucials sobre les targetes de crèdit. La nova taula ha de ser capaç d'identificar de manera única cada targeta 
i establir una relació adequada amb les altres dues taules ("transaction" i "company"). Després de crear la taula 
serà necessari que ingressis la informació del document denominat "dades_introduir_credit". Recorda mostrar el diagrama i 
realitzar una breu descripció d'aquest.*/
USE transactions;
CREATE TABLE credit_card (
    id VARCHAR(20) PRIMARY KEY,
    iban VARCHAR(34),
    pan VARCHAR(19),
    pin VARCHAR(4),
    cvv VARCHAR(3),
    expiring_date VARCHAR(255) # Es fa servir cadena de text per emmagatzermar les dates, i convertir-les posteriorment.
);

UPDATE credit_card 
SET expiring_date = STR_TO_DATE(`expiring_date`, '%m/%d/%y')
WHERE id IS NOT NULL;

ALTER TABLE credit_card MODIFY COLUMN expiring_date DATE;
DESCRIBE credit_card;

ALTER TABLE transaction
ADD CONSTRAINT fk_transaction_credit_card
FOREIGN KEY (credit_card_id)
REFERENCES credit_card(id);

-- Exercici 2 --
/* El departament de Recursos Humans ha identificat un error en el número de compte associat a la targeta de crèdit amb ID CcU-2938. 
La informació que ha de mostrar-se  per a aquest registre és: TR323456312213576817699999. Recorda mostrar que el canvi es va realitzar.*/

UPDATE credit_card
SET iban = 'TR323456312213576817699999'
WHERE id = 'CcU-2938';

-- Exercici 3 --
/* En la taula "transaction" ingressa un nou usuari amb la següent informació:
Id	= 108B1D1D-5B23-A76C-55EF-C568E49A99DD
credit_card_id	= CcU-9999
company_id= b-9999
user_id	= 9999
lat	= 829.999
longitude =-117.999
amount = 111.11
declined = 0 */
# Primer s'ha de crear l'empresa en la taula company i en la taula credit card, ja que la in
INSERT INTO company (
    id,
    company_name,
    phone,
    email,
    country,
    website
) VALUES (
    'b-9999',
    NULL,
    NULL,
    NULL,
    NULL,
    NULL
);
INSERT INTO credit_card (
    id,
    iban,
    pan,
    pin,
    cvv,
    expiring_date
) VALUES (
    'CcU-9999',
     NULL,
     NULL,
     NULL,
     NULL,
     NULL
);

INSERT INTO transaction (
    id,
    credit_card_id,
    company_id,
    user_id,
    lat,
    longitude,
    timestamp,
    amount,
    declined
) VALUES (
    '108B1D1D-5B23-A76C-55EF-C568E49A99DD',
    'CcU-9999',
    'b-9999',
    9999,
    829.999,
    -117.999,
    CURRENT_TIMESTAMP,  # Es guarda l’hora actual
    111.11,
    0
);
SELECT * FROM transaction WHERE id = '108B1D1D-5B23-A76C-55EF-C568E49A99DD'; #Comprobació de la creació de la linea

-- Exercici 4--
-- Des de recursos humans et sol·liciten eliminar la columna "pan" de la taula credit_card. Recorda mostrar el canvi realitzat. --

ALTER TABLE credit_card
DROP COLUMN pan;
SELECT * FROM credit_card;

-- NIVELL 2 --
-- EXERCICI 1 --
-- Elimina de la taula transaction el registre amb ID 000447FE-B650-4DCF-85DE-C7ED0EE1CAAD de la base de dades.--
SELECT * FROM transaction WHERE id = '000447FE-B650-4DCF-85DE-C7ED0EE1CAAD';
DELETE FROM transaction WHERE id = '000447FE-B650-4DCF-85DE-C7ED0EE1CAAD';
SELECT * FROM transaction WHERE id = '000447FE-B650-4DCF-85DE-C7ED0EE1CAAD';

-- EXERCICI 2 --
/* La secció de màrqueting desitja tenir accés a informació específica per a realitzar anàlisi i estratègies efectives. 
S'ha sol·licitat crear una vista que proporcioni detalls clau sobre les companyies i les seves transaccions.
 Serà necessària que creïs una vista anomenada VistaMarketing que contingui la següent informació: Nom de la companyia. 
 Telèfon de contacte. País de residència. Mitjana de compra realitzat per cada companyia. */
 
CREATE VIEW VistaMarketing AS
SELECT 
    c.company_name AS Entitat,
    c.phone AS Telèfon,
    c.country AS País,
    ROUND(AVG(t.amount),2) AS Mitjana_Compra
FROM 
    company c
INNER JOIN 
    transaction t ON c.id = t.company_id
GROUP BY 
    c.company_name, c.phone, c.country
ORDER BY 
    Mitjana_Compra DESC;

SELECT * FROM VistaMarketing;

-- EXERCICI 3 --
SELECT * 
FROM VistaMarketing
WHERE País = 'Germany';

-- NIVELL 3 --
-- EXERCICI 1 --

CREATE TABLE IF NOT EXISTS user (
	id CHAR(10) PRIMARY KEY,
	name VARCHAR(100),
	surname VARCHAR(100),
	phone VARCHAR(150),
	email VARCHAR(150),
	birth_date VARCHAR(100),
	country VARCHAR(150),
	city VARCHAR(150),
	postal_code VARCHAR(100),
	address VARCHAR(255)    
);
ALTER TABLE user MODIFY id INT NOT NULL; # Igualar la descripció de la variable per evitar incompatibilitat
# Creació del registre user_id = 9999.
INSERT INTO user (
    id,
    name,
    surname,
    phone,
    email,
    birth_date,
    country,
    city,
    postal_code,
    address
) VALUES (
    '9999',
     NULL,
     NULL,
     NULL,
     NULL,
     NULL,
     NULL,
     NULL,
     NULL,
     NULL
);


ALTER TABLE transaction
ADD CONSTRAINT fk_transaction_user FOREIGN KEY (user_id) REFERENCES user(id);

-- Exercici 2 --
/* L'empresa també us demana crear una vista anomenada "InformeTecnico" que contingui la següent informació:
ID de la transacció, Nom de l'usuari/ària, Cognom de l'usuari/ària, IBAN de la targeta de crèdit usada, Nom de la companyia de la transacció realitzada.
Assegureu-vos d'incloure informació rellevant de les taules que coneixereu i utilitzeu àlies per canviar de nom columnes segons calgui.
Mostra els resultats de la vista, ordena els resultats de forma descendent en funció de la variable ID de transacció.*/

CREATE VIEW InformeTecnico AS
SELECT 
    t.id AS ID_Transaccio,
    u.name AS Nom_Usuari,
    u.surname AS Cognom_Usuari,
    cc.iban AS IBAN_Targeta,
    c.company_name AS Entitat
FROM 
    transaction t
JOIN 
    user u ON t.user_id = u.id
JOIN 
    credit_card cc ON t.credit_card_id = cc.id
JOIN 
    company c ON t.company_id = c.id
ORDER BY 
    t.id DESC;
SELECT * FROM InformeTecnico;
