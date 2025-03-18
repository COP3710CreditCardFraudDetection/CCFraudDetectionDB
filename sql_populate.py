import pandas as pd


def escape_str(val):
    """Escape single quotes for SQL string literals."""
    if isinstance(val, str):
        return val.replace("'", "''")
    return val


# ------------- STATE INSERTS -------------
states = {
    "AL": "Alabama", "AK": "Alaska", "AZ": "Arizona", "AR": "Arkansas",
    "CA": "California", "CO": "Colorado", "CT": "Connecticut", "DE": "Delaware",
    "DC": "District of Columbia",  # Added DC
    "FL": "Florida", "GA": "Georgia", "HI": "Hawaii", "ID": "Idaho",
    "IL": "Illinois", "IN": "Indiana", "IA": "Iowa", "KS": "Kansas",
    "KY": "Kentucky", "LA": "Louisiana", "ME": "Maine", "MD": "Maryland",
    "MA": "Massachusetts", "MI": "Michigan", "MN": "Minnesota", "MS": "Mississippi",
    "MO": "Missouri", "MT": "Montana", "NE": "Nebraska", "NV": "Nevada",
    "NH": "New Hampshire", "NJ": "New Jersey", "NM": "New Mexico", "NY": "New York",
    "NC": "North Carolina", "ND": "North Dakota", "OH": "Ohio", "OK": "Oklahoma",
    "OR": "Oregon", "PA": "Pennsylvania", "RI": "Rhode Island", "SC": "South Carolina",
    "SD": "South Dakota", "TN": "Tennessee", "TX": "Texas", "UT": "Utah",
    "VT": "Vermont", "VA": "Virginia", "WA": "Washington", "WV": "West Virginia",
    "WI": "Wisconsin", "WY": "Wyoming"
}

state_inserts = []
for code, name in states.items():
    stmt = f"INSERT INTO states (state_code, state_name) VALUES ('{escape_str(code)}', '{escape_str(name)}');"
    state_inserts.append(stmt)

# ------------- READ CSV & PREPARE OCCUPATION MAPPING -------------
# Load only the first 10,000 records and skip the header row.
df = pd.read_csv('archive/fraudTest.csv', skiprows=1, header=None, nrows=10000, low_memory=False)

# Get unique job values from column index 16
unique_jobs = df[16].unique()
job_to_occ_id = {}
for i, job in enumerate(unique_jobs, start=1):
    job_to_occ_id[job] = i

occupation_inserts = []
for job, occ_id in job_to_occ_id.items():
    stmt = f"INSERT INTO occupation (occupation_id, job) VALUES ({occ_id}, '{escape_str(job)}');"
    occupation_inserts.append(stmt)

# ------------- INITIALIZE OTHER COUNTERS -------------
cardholder_id_counter = 1
location_id_counter = 1
merchant_id_counter = 1
merchant_cat_id_counter = 1

# Lists to hold SQL INSERT statements for each table
cardholder_inserts = []
location_inserts = []
merchant_inserts = []
merchant_category_inserts = []
transactions_inserts = []

# ------------- PROCESS EACH ROW -------------
for idx, row in df.iterrows():
    # Extract values from the CSV row based on the defined order:
    # [0] transaction_id, [1] transaction_date, [2] cc_num, [3] merchant,
    # [4] category, [5] amt, [6] first, [7] last, [8] gender, [9] street,
    # [10] city, [11] state, [12] zip, [13] lat, [14] long, [15] city_pop,
    # [16] job, [17] dob, [18] trans_num, [19] unix_time, [20] merch_lat,
    # [21] merch_long, [22] is_fraud

    transaction_id = row[0]
    full_timestamp = row[1]  # e.g., "2020-06-21 12:14:25"
    transaction_date = full_timestamp.split()[0]  # "2020-06-21"
    merchant_raw = row[3]  # e.g., "fraud_Kirlin and Sons"
    merchant_name = merchant_raw.replace("fraud_", "")  # Remove "fraud_" prefix
    category_name = row[4]
    amount = row[5]
    first_name = row[6]
    last_name = row[7]
    gender_raw = row[8]
    # Map gender to enum values
    if str(gender_raw).upper() == 'M':
        gender = "Male"
    elif str(gender_raw).upper() == 'F':
        gender = "Female"
    else:
        gender = "Other"
    street = row[9]
    city = row[10]
    state_code = row[11]  # Should match a state code from the state table
    zip_code = row[12]
    latitude = row[13]
    longitude = row[14]
    city_pop = row[15]
    job = row[16]  # Job string from CSV
    dob = row[17]
    unix_time = row[19]
    merch_lat = row[20]
    merch_long = row[21]
    is_fraud = 'FALSE' if str(row[22]).strip() in ['0', 'False', 'false'] else 'TRUE'

    # Lookup occupation_id for the job
    occupation_id = job_to_occ_id[job]

    # 1. INSERT for cardholder table (columns: cardholder_id, first_name, last_name, dob, occupation_id, gender)
    cardholder_sql = (
        f"INSERT INTO cardholder (cardholder_id, first_name, last_name, dob, occupation_id, gender) "
        f"VALUES ({cardholder_id_counter}, '{escape_str(first_name)}', '{escape_str(last_name)}', '{escape_str(dob)}', {occupation_id}, '{escape_str(gender)}');"
    )
    cardholder_inserts.append(cardholder_sql)

    # 2. INSERT for cardholder_location table
    location_sql = (
        f"INSERT INTO cardholder_location (location_id, cardholder_id, street, city, state_code, zip_code, latitude, longitude, city_pop) "
        f"VALUES ({location_id_counter}, {cardholder_id_counter}, '{escape_str(street)}', '{escape_str(city)}', '{escape_str(state_code)}', '{escape_str(zip_code)}', {latitude}, {longitude}, {city_pop});"
    )
    location_inserts.append(location_sql)

    # 3. INSERT for merchant_category table (without merchant_id to avoid circular reference)
    merchant_category_sql = (
        f"INSERT INTO merchant_category (merchant_cat_id, category_name) "
        f"VALUES ({merchant_cat_id_counter}, '{escape_str(category_name)}');"
    )
    merchant_category_inserts.append(merchant_category_sql)

    # 4. INSERT for merchant table
    merchant_sql = (
        f"INSERT INTO merchant (merchant_id, merchant_name, merchant_cat_id, merchant_lat, merchant_long) "
        f"VALUES ({merchant_id_counter}, '{escape_str(merchant_name)}', {merchant_cat_id_counter}, {merch_lat}, {merch_long});"
    )
    merchant_inserts.append(merchant_sql)

    # 5. INSERT for transactions table
    transaction_sql = (
        f"INSERT INTO transactions (transaction_id, cardholder_id, merchant_id, transaction_date, amount, unix_time, is_fraud) "
        f"VALUES ({transaction_id}, {cardholder_id_counter}, {merchant_id_counter}, '{escape_str(transaction_date)}', {amount}, {unix_time}, {is_fraud});"
    )
    transactions_inserts.append(transaction_sql)

    # Update counters for the next row
    cardholder_id_counter += 1
    location_id_counter += 1
    merchant_id_counter += 1
    merchant_cat_id_counter += 1

# ------------- WRITE ALL INSERT STATEMENTS TO FILE -------------
with open("archive/insert_statements.sql", "w", encoding="utf-8") as f:
    f.write("-- State Inserts\n")
    for stmt in state_inserts:
        f.write(stmt + "\n")

    f.write("\n-- Occupation Inserts\n")
    for stmt in occupation_inserts:
        f.write(stmt + "\n")

    f.write("\n-- Merchant Category Inserts\n")
    for stmt in merchant_category_inserts:
        f.write(stmt + "\n")

    f.write("\n-- Cardholder Inserts\n")
    for stmt in cardholder_inserts:
        f.write(stmt + "\n")

    f.write("\n-- Cardholder Location Inserts\n")
    for stmt in location_inserts:
        f.write(stmt + "\n")

    f.write("\n-- Merchant Inserts\n")
    for stmt in merchant_inserts:
        f.write(stmt + "\n")

    f.write("\n-- Transactions Inserts\n")
    for stmt in transactions_inserts:
        f.write(stmt + "\n")

print("SQL insert statements have been written to insert_statements.sql")
