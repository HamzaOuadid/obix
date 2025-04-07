@echo off
echo Building and starting Docker containers in detached mode...

docker-compose down
docker-compose build
docker-compose up -d

echo Done. To view logs, use 'docker-compose logs -f' 