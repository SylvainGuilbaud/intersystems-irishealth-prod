if [ ! -s ./iris/key/iris.key ]; then
  if [ -s ./iris/key/iris.key.to_replace_with_your_IRIS_key ]; then
    cp ./iris/key/iris.key.to_replace_with_your_IRIS_key ./iris/key/iris.key
    echo "[start.sh] Copied ./iris/key/iris.key.to_replace_with_your_IRIS_key to ./iris/key/iris.key"
  else
    echo "[start.sh] ERROR: ./iris/key/iris.key is missing or empty."
    echo "[start.sh] Place a valid IRIS key file at ./iris/key/iris.key before starting."
    exit 1
  fi
fi

if ! grep -q "^FileType=InterSystems License" ./iris/key/iris.key; then
  echo "[start.sh] ERROR: ./iris/key/iris.key is not an InterSystems license file."
  echo "[start.sh] Expected a key file with 'FileType=InterSystems License'."
  exit 1
fi

docker compose down
docker run --rm -v intersystems-irishealth-prod_iris-data:/iris-data alpine \
  sh -c "chown -R 51773:51773 /iris-data && chmod -R u+rwX /iris-data"
# docker compose up -d 
docker compose up -d --build --remove-orphans