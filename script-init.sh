# Cargo variables del .env
if [ -f .env ]; then
  export $(grep -v '^#' .env | xargs)
else
  echo ".env file not found."
  exit 1
fi

POSTGRES_CONTAINER="dssd-2024-docker-db-1"
API_CONTAINER="dssd-2024-docker-api-1"
SQL_SCRIPT_PATH="/docker-entrypoint-initdb.d/scripts/inicializacion.sql"

if [ -z "$DB_USER" ] || [ -z "$DB_NAME" ]; then
  echo "Error: DB_USER and/or DB_NAME are not set."
  exit 1
fi

echo "Esperando que PostgreSQL este disponible..."
until docker exec -t "$POSTGRES_CONTAINER" pg_isready -U "$DB_USER" > /dev/null 2>&1; do
  sleep 2
  echo "Esperando a PostgreSQL..."
done

echo "PostgreSQL esta listo, inicializando la bd grupodssd..."
docker exec -i "$POSTGRES_CONTAINER" psql -U postgres -f "$SQL_SCRIPT_PATH"

if [ $? -eq 0 ]; then
  echo "SQL script executed successfully."
else
  echo "Error executing SQL script."
  exit 1
fi

# Levanto la API en segundo plano
echo "Conectandose al contenedor de la api"
docker exec -d "$API_CONTAINER" bash -c "npm run start:dev"  

if [ $? -eq 0 ]; then
  echo "API iniciada correctamente"
else
  echo "Error iniciando la API."
  exit 1
fi

