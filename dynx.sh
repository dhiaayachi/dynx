#!/usr/bin/env bash


if [ "$#" -lt 1 ]; then
    echo -e "possible commands are:"
    echo -e "\ttest: run unit tests"
    echo -e "\tbuild: build docker images"
    echo -e "\tdeploy: deploy docker images"
    echo -e "\tteste2d: run end to end tests"
    echo -e "\tclean: remove the docker stack if it exist"
    exit 1
fi


TEST=0
BUILD=0
DEPLOY=0
TESTE2E=0
CLEAN=0

POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    test)
    TEST=1
    shift # past argument
    ;;
    build)
    BUILD=1
    shift # past argument
    ;;
    deploy)
    DEPLOY=1
    shift # past argument
    ;;
    teste2e)
    TESTE2E=1
    shift # past argument
    ;;
    clean)
    CLEAN=1
    shift # past argument
    ;;
    *)    # unknown option
    POSITIONAL+=("$1") # save it in an array for later
    shift # past argument
    ;;
esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters


if [ "$CLEAN" -eq 1 ]; then
    docker stack rm dynx
fi

if [ "$TEST" -eq 1 ]; then
    docker build -t test_resty -f TestDockerfile . || exit 1
    docker run  -v "$(pwd)/resty/test:/test" test_resty resty *.lua || exit 1
fi

if [ "$BUILD" -eq 1 ]; then
    docker build -t router . || exit 1
fi

if [ "$DEPLOY" -eq 1 ]; then
		docker deploy -c docker-compose.yml dynx || exit 1
fi

if [ "$TESTE2E" -eq 1 ]; then
    echo "not implemented yet"
fi
