# One Node Scipion Web Tools Portal

This is an example of deployment of one node Scipion Web Tools (https://github.com/I2PC/scipion-web) portal
started via OCCI on EGI FedCloud. Service deployment is managed by custom
Puppet interface which supports r10k (Puppetfile), Hiera bindings
and access to Cloudify context (ctx). Tested on CentOS 7.x.

This example was prepared for purposes of *Cloud Orchestration Training* organized by MU within H2020 West-Life project (http://about.west-life.eu/).

## Standalone Cloudify

#### Setup OCCI CLI

```bash
yum install -y ruby-devel openssl-devel gcc gcc-c++ ruby rubygems
gem install occi-cli
```

#### Setup cloudify

```bash
make bootstrap
```

#### Run deployment

First get valid X.509 VOMS certificate into `/tmp/x509up_u1000` and
have `m4` installed.

```bash
source ~/cfy/bin/activate
make cfy-deploy
```

If succeeded, see deployed Apache endpoint URL. E.g.:

```bash
cfy local outputs
{
  "endpoint": {
    "url": "http://147.228.242.209"
  }
}
```

and open provided URL in your browser to see working
connection between webserver and database.

#### Destroy deployment

```bash
make cfy-undeploy
```
