#!/bin/bash -e
#
# Install Snowflake Python Connector
#
set -o pipefail

THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

env | sort

if [ "$TRAVIS_OS_NAME" == "osx" ]; then
    curl -O https://www.python.org/ftp/python/${PYTHON_VERSION}/python-${PYTHON_VERSION}-macosx10.9.pkg
    sudo installer -pkg python-${PYTHON_VERSION}-macosx10.9.pkg -target /
    which python3
    python3 --version
    python3 -m venv venv
else
    pip install -U virtualenv
    python -m virtualenv venv
fi

TRAVIS_PYTHON_VERSION=$(python -c 'import sys; print(".".join([str(c) for c in sys.version_info[0:2]]))')

# TODO: decrypto credentials

source ./venv/bin/activate

if [ "$TRAVIS_OS_NAME" == "osx" ]; then
    export ENABLE_EXT_MODULES=true
    cd $THIS_DIR/..
    pip install Cython pyarrow==0.15.1 wheel
    python setup.py bdist_wheel
    unset ENABLE_EXT_MODULES
    CONNECTOR_WHL=$(ls $THIS_DIR/../dist/snowflake_connector_python*.whl | sort -r | head -n 1)
    pip install -U ${CONNECTOR_WHL}[pandas,development]
else
    if [[ "$TRAVIS_PYTHON_VERSION" == "2.7" ]]; then
         pip install .[pandas,development]
    else
        pv=${TRAVIS_PYTHON_VERSION/./}
        $THIS_DIR/build_inside_docker.sh $pv
        CONNECTOR_WHL=$(ls $THIS_DIR/../dist/docker/repaired_wheels/snowflake_connector_python*cp${PYTHON_ENV}*.whl | sort -r | head -n 1)
        pip install -U ${CONNECTOR_WHL}[pandas,development]
        cd $THIS_DIR/..
    fi
fi
pip list --format=columns
