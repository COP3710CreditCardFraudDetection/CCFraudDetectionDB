

-- Create an ENUM type for gender to ensure consistency in gender data
CREATE TYPE gender_enum as ENUM ('Male', 'Female', 'Nonbinary', 'Other');

-- Create the occupation table to store unique occupations
CREATE TABLE occupation (
    occupation_id INT PRIMARY KEY,	-- Unique ID for each occupation
    job VARCHAR(100) NOT NULL		-- Job title 
);


-- Create the cardholder table 
CREATE TABLE cardholder (
    cardholder_id INT PRIMARY KEY,	-- Unique identifier for each cardholder
    first_name VARCHAR(50) NOT NULL,	-- First name of the cardholder
    last_name VARCHAR(50) NOT NULL,	-- Last name of the cardholder
    dob DATE NOT NULL CHECK (dob < CURRENT_DATE AND dob > '1900-01-01'),	-- Date of birth must be before today and after 1900 (to prevent invalid entries)
    occupation_id INT NOT NULL,	-- Foreign key linking to the occupation table
    gender gender_enum NOT NULL,	-- Gender stored as an ENUM type
    FOREIGN KEY (occupation_id) REFERENCES occupation(occupation_id)	-- Ensures occupation_id references a valid job in the occupation table
);

--Created a state code to save space and repititon.
--Will need to be populated before used
CREATE TABLE states (
    state_code CHAR(2) PRIMARY KEY,	-- Standard two-letter state abbreviation
    state_name VARCHAR(50) NOT NULL	-- Full state name
);


CREATE TABLE cardholder_location (
    location_id INT PRIMARY KEY,	-- Unique identifier for each location entry
    cardholder_id INT,				-- Foreign key linking to the cardholder table
    street VARCHAR(50) NOT NULL,	-- Street address of the cardholder
    city VARCHAR(50) NOT NULL,		-- City where the cardholder resides
    state_code CHAR(2) NOT NULL,	-- State code (linked to the states table)
    zip_code VARCHAR(10) NOT NULL,	-- Zip code of the cardholder's residence
    latitude DECIMAL(10,8) NOT NULL,	-- Geographical latitude of the cardholder’s home
    longitude DECIMAL(11,8) NOT NULL,	-- Geographical longitude of the cardholder’s home
    city_pop NUMERIC(8,0) NOT NULL,	-- Population of the city where the cardholder lives
    FOREIGN KEY (cardholder_id) REFERENCES cardholder(cardholder_id),	-- Ensures location entry is linked to a valid cardholder
    FOREIGN KEY (state_code) REFERENCES states(state_code)		-- Ensures the state is valid based on the states table
);

--Created table to store merchant categories to avoid repitition.
--Each merchant is a one-to-one relationship.
--Must be populated before using
CREATE TABLE merchant_category (
	merchant_cat_id INT PRIMARY KEY,	-- Unique ID for each merchant category
	category_name VARCHAR(32) NOT NULL	-- Name of the category
);

-- Create the merchant table to store details about businesses where transactions occur
CREATE TABLE merchant (
	merchant_id INT PRIMARY KEY,	-- Unique identifier for each merchant
	merchant_name VARCHAR(50) NOT NULL,	-- Merchant's name (e.g., Amazon, Walmart)
	merchant_cat_id INT,					-- Foreign key linking to the merchant category table
	merchant_lat DECIMAL(10,8) NOT NULL,	-- Latitude of the merchant’s location
	merchant_long DECIMAL(11,8) NOT NULL,	-- Longitude of the merchant’s location

	FOREIGN KEY (merchant_cat_id) REFERENCES merchant_category (merchant_cat_id)	-- Ensures merchant category is valid and prevents invalid category entries
);

-- Create the transactions table to store details of each credit card transaction
CREATE TABLE transactions (
    transaction_id INT PRIMARY KEY,	-- Unique identifier for each transaction
    cardholder_id INT NOT NULL,		-- Foreign key linking to the cardholder table
	merchant_id INT NOT NULL,			-- Foreign key linking to the merchant table
    transaction_date DATE NOT NULL,	-- Date when the transaction occurred
    amount NUMERIC(6,2) CHECK (amount >= 0),
    unix_time INT NOT NULL,				-- UNIX timestamp of the transaction
    is_fraud BOOL,						-- Boolean flag (TRUE if fraud, FALSE otherwise)
    FOREIGN KEY (cardholder_id) REFERENCES cardholder(cardholder_id),		-- Ensures transactions are linked to a valid cardholder
	FOREIGN KEY (merchant_id) REFERENCES merchant (merchant_id)			-- Ensures transactions are linked to a valid merchant
);

