docker-compose down
if [ "$1" = "rm" ]; then
    docker volume rm $(docker volume ls -q)
    docker rmi -f $(docker images -q)
    docker volume create --name=pgdata
fi
docker-compose up --build --remove-orphans