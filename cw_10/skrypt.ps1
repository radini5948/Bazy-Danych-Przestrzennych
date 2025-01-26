# Skrypt: Automatyzacja przetwarzania danych klientów
# Autor: Radoslaw Beta
# Data: 26.01.2025

# Parametry
$NUMERINDEKSU = "414568"
$TIMESTAMP = (Get-Date -Format "MMddyyyy")
$URL_FILE = "https://home.agh.edu.pl/~wsarlej/Customers_Nov2024.zip"
$URL_OLD_FILE = "https://home.agh.edu.pl/~wsarlej/Customers_old.csv"
$OLD_FILE = "Customers_old.csv"
$DB_HOST = "localhost"
$DB_USER = "postgres"
$DB_NAME = "cw10"
$EMAIL_RECIPIENT = "RadekBeta@gmail.com"
$LOG_FILE = "PROCESSED/script_log_${TIMESTAMP}.log"
$PROCESSED_DIR = "PROCESSED"

# Tworzenie folderu na przetworzone pliki
if (-not (Test-Path -Path $PROCESSED_DIR)) {
    New-Item -ItemType Directory -Path $PROCESSED_DIR | Out-Null
}

# Funkcja logowania
function Log {
    param([string]$Message)
    $LogEntry = "$(Get-Date -Format "yyyyMMddHHmmss") - $Message"
    $LogEntry | Tee-Object -FilePath $LOG_FILE -Append
}

# Obsługa błędów
function Handle-Error {
    param([string]$ErrorMessage)
    Log "ERROR: $ErrorMessage"
    exit 1
}

# Sprawdzenie dostępności narzędzi
function Check-Command {
    param([string]$CommandName)
    if (-not (Get-Command $CommandName -ErrorAction SilentlyContinue)) {
        Handle-Error "$CommandName is not installed"
    }
}

Check-Command "Invoke-WebRequest"
Check-Command "Expand-Archive"
Check-Command "Compress-Archive"
Check-Command "psql"

# Tworzenie rozszerzenia PostGIS
Log "Ensuring PostGIS extension is installed..."
try {
    Invoke-Expression "psql -h $DB_HOST -U $DB_USER -d $DB_NAME -c 'CREATE EXTENSION IF NOT EXISTS postgis;'"
} catch {
    Handle-Error "Failed to create PostGIS extension"
}

# Pobieranie plików
Log "Downloading file..."
try {
    Invoke-WebRequest -Uri $URL_FILE -OutFile "Customers_Nov2024.zip"
    Invoke-WebRequest -Uri $URL_OLD_FILE -OutFile $OLD_FILE
} catch {
    Handle-Error "Failed to download files: $_"
}

# Rozpakowanie pliku ZIP
Log "Unzipping file..."
try {
    Expand-Archive -Path "Customers_Nov2024.zip" -DestinationPath "." -Force
} catch {
    Handle-Error "Failed to unzip Customers_Nov2024.zip: $_"
}

# Walidacja i deduplikacja danych
Log "Validating and cleaning file..."
try {
    $Header = Get-Content -Path "Customers_Nov2024.csv" -First 1
    $Rows = Import-Csv "Customers_Nov2024.csv"

    $ValidRows = @()
    $InvalidRows = @()
    $SeenRows = @{}

    foreach ($Row in $Rows) {
        if ($Row.email -match '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$') {
            if (-not $SeenRows.ContainsKey($Row)) {
                $ValidRows += $Row
                $SeenRows[$Row] = $true
            } else {
                $InvalidRows += $Row
            }
        } else {
            $InvalidRows += $Row
        }
    }

    $ValidRows | Export-Csv -Path "Customers_Nov2024.valid" -NoTypeInformation
    $InvalidRows | Export-Csv -Path "Customers_Nov2024.bad_${TIMESTAMP}" -NoTypeInformation
} catch {
    Handle-Error "Validation failed: $_"
}

# Porównanie z plikiem OLD
Log "Removing duplicates with old data..."
try {
    $OldRows = Get-Content -Path $OLD_FILE
    $FinalRows = $ValidRows | Where-Object { -not $OldRows.Contains($_) }
    $FinalRows | Export-Csv -Path "Customers_Nov2024.final" -NoTypeInformation
} catch {
    Handle-Error "Failed to create final file: $_"
}

# Tworzenie tabeli w PostgreSQL
Log "Setting up PostgreSQL table..."
try {
    Invoke-Expression "psql -h $DB_HOST -U $DB_USER -d $DB_NAME -c '
    DROP TABLE IF EXISTS CUSTOMERS_$NUMERINDEKSU;
    CREATE TABLE CUSTOMERS_$NUMERINDEKSU (
        imie TEXT,
        nazwisko TEXT,
        email TEXT,
        lat NUMERIC,
        lon NUMERIC,
        geoloc GEOGRAPHY(POINT, 4326)
    );'"
} catch {
    Handle-Error "Failed to create table: $_"
}

# Ładowanie danych
Log "Loading data into PostgreSQL..."
try {
    Invoke-Expression "psql -h $DB_HOST -U $DB_USER -d $DB_NAME -c '\copy CUSTOMERS_$NUMERINDEKSU(imie, nazwisko, email, lat, lon) FROM Customers_Nov2024.final WITH CSV HEADER;'"
    Invoke-Expression "psql -h $DB_HOST -U $DB_USER -d $DB_NAME -c 'UPDATE CUSTOMERS_$NUMERINDEKSU SET geoloc = ST_SetSRID(ST_MakePoint(lon, lat), 4326);'"
} catch {
    Handle-Error "Failed to load data: $_"
}

# Generowanie raportu
Log "Generating report..."
try {
    $ReportContent = @(
        "Liczba wierszy w pliku pobranym z internetu: $(Get-Content -Path Customers_Nov2024.csv | Measure-Object -Line).Lines",
        "Liczba poprawnych wierszy (po czyszczeniu): $(Get-Content -Path Customers_Nov2024.final | Measure-Object -Line).Lines"
    )
    $ReportContent | Out-File -FilePath "CUSTOMERS_LOAD_${TIMESTAMP}.dat"
} catch {
    Handle-Error "Failed to generate report: $_"
}

# Kwerenda SQL dla klientów w promieniu 50 km
Log "Finding best customers..."
try {
    Invoke-Expression "psql -h $DB_HOST -U $DB_USER -d $DB_NAME -c '
    CREATE TABLE IF NOT EXISTS BEST_CUSTOMERS_$NUMERINDEKSU AS
    SELECT imie, nazwisko
    FROM CUSTOMERS_$NUMERINDEKSU
    WHERE ST_Distance(geoloc, ST_SetSRID(ST_MakePoint(-75.67329768604034, 41.39988501005976), 4326)::geography) <= 50000;'"
} catch {
    Handle-Error "Failed to execute SQL query: $_"
}

# Eksport danych do CSV
Log "Exporting best customers to CSV..."
try {
    Invoke-Expression "psql -h $DB_HOST -U $DB_USER -d $DB_NAME -c '\copy BEST_CUSTOMERS_$NUMERINDEKSU TO BEST_CUSTOMERS_$NUMERINDEKSU.csv WITH CSV HEADER;'"
} catch {
    Handle-Error "Failed to export data: $_"
}

# Kompresja wyników
Log "Compressing CSV file..."
try {
    Compress-Archive -Path "BEST_CUSTOMERS_$NUMERINDEKSU.csv" -DestinationPath "BEST_CUSTOMERS_$NUMERINDEKSU.zip"
} catch {
    Handle-Error "Failed to compress CSV file: $_"
}

Log "Script execution completed successfully."
