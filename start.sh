docker compose down
docker run --rm -v intersystems-irishealth-prod_iris-data:/iris-data ubuntu \
  bash -c "chown -R 51773:51773 /iris-data && chmod -R u+rwX /iris-data"
# docker compose up -d 
docker compose up -d --build --remove-orphans