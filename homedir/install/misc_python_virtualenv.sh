#!/usr/bin/env bash
virtualenv -p`which python3` py3
source py3/bin/activate
pip install mxnet-cu101
git clone git@github.com:dmlc/gluon-cv.git
cd gluon-cv
pip install -e .
pip install ipython
pip install horovod
wget https://gluon-cv.mxnet.io/_downloads/b6ade342998e03f5eaa0f129ad5eee80/mscoco.py
pip install --upgrade cython
pip install pycocotools
python mscoco.py

