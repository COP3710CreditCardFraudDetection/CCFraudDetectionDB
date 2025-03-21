--TO DO: Add more check to each attribute and determine
--whether or not each attribute has enough space allocated.


CREATE TYPE gender_enum as ENUM ('Male', 'Female', 'Nonbinary', 'Other');

-- Create the occupation table to store unique occupations
CREATE TABLE occupation (
    occupation_id INT PRIMARY KEY,
    job VARCHAR(100) NOT NULL
);


-- Create the cardholder table 
CREATE TABLE cardholder (
    cardholder_id INT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    dob DATE NOT NULL CHECK (dob < CURRENT_DATE AND dob > '1900-01-01'),
    occupation_id INT NOT NULL,
    gender gender_enum NOT NULL,
    FOREIGN KEY (occupation_id) REFERENCES occupation(occupation_id)
);

--Created a state code to save space and repititon.
--Will need to be populated before used
CREATE TABLE states (
    state_code CHAR(2) PRIMARY KEY,
    state_name VARCHAR(50) NOT NULL
);

--removed these:
--ALTER TABLE cardholder_location
--ALTER COLUMN city TYPE VARCHAR(50);

CREATE TABLE cardholder_location (
    location_id INT PRIMARY KEY,
    cardholder_id INT,
    street VARCHAR(50) NOT NULL,
    city VARCHAR(50) NOT NULL,
    state_code CHAR(2) NOT NULL,
    zip_code VARCHAR(10) NOT NULL,
    latitude DECIMAL(10,8) NOT NULL,
    longitude DECIMAL(11,8) NOT NULL,
    city_pop NUMERIC(8,0) NOT NULL,
    FOREIGN KEY (cardholder_id) REFERENCES cardholder(cardholder_id),
    FOREIGN KEY (state_code) REFERENCES states(state_code)
);

--Created table to store merchant categories to avoid repitition.
--Each merchant is a one-to-one relationship.
--Must be populated before using
CREATE TABLE merchant_category (
	merchant_cat_id INT PRIMARY KEY,
	category_name VARCHAR(32) NOT NULL
);

CREATE TABLE merchant (
	merchant_id INT PRIMARY KEY,
	merchant_name VARCHAR(50) NOT NULL,
	merchant_cat_id INT,
	merchant_lat DECIMAL(10,8) NOT NULL,
	merchant_long DECIMAL(11,8) NOT NULL,

	FOREIGN KEY (merchant_cat_id) REFERENCES merchant_category (merchant_cat_id)
);


CREATE TABLE transactions (
    transaction_id INT PRIMARY KEY,
    cardholder_id INT NOT NULL,
	merchant_id INT NOT NULL,
    transaction_date DATE NOT NULL,
    amount NUMERIC(6,2) CHECK (amount >= 0),
    unix_time INT NOT NULL,
    is_fraud BOOL,
    FOREIGN KEY (cardholder_id) REFERENCES cardholder(cardholder_id),
	FOREIGN KEY (merchant_id) REFERENCES merchant (merchant_id)
);

