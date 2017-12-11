docker stack rm dynx
docker build -t router .
docker deploy -c docker-compose.yml dynx
