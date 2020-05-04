#!/bin/bash
set -e

PIP3='sudo pip3 install -q -U --no-cache'
APT='sudo apt -qq -y install'

echo "* Installing apt dependencies"
  $APT golang iputils-arping

mingoversion=go1.12
echo -n "* Checking for go version $mingoversion or later: "
  goversion=$(go version | awk '{print $3;}')
  latest=`printf "$mingoversion\n%s" $goversion | sort -V | tail -n1`
  echo $goversion
  if [ "$latest" != "$goversion" ]; then
      echo "test requires go version >= $mingoversion (found $goversion)"
      exit 1
  fi

echo "* Installing gnxi tools"
  if [ "$GOPATH" == "" ]; then
    export GOPATH=$HOME/go
    echo "* GOPATH not set - using $GOPATH"
  fi
  mkdir -p $GOPATH
  export PATH=$GOPATH/bin:$PATH
  repo=github.com/google/gnxi
  for tool in gnmi_{capabilities,get,set,target}; do
    go get $repo/$tool
    go install $repo/$tool
  done

echo "* Installing python dependencies"
  $PIP3 flake8 pylint protobuf grpcio grpcio-tools requests prometheus-client

echo "* Installing latest faucet"
  $PIP3 --upgrade git+https://github.com/faucetsdn/faucet

echo "* Installing latest mininet and dependencies"
  $APT openvswitch-switch net-tools telnet
  sudo service openvswitch-switch start
  TMPDIR=$(mktemp -d) && pushd $TMPDIR
  git clone https://github.com/mininet/mininet
  cd mininet
  sudo make install-mnexec
  $PIP3 .
  popd && sudo rm -rf $TMPDIR

echo "* Done"
