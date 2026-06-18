# Why

- Are you apprehensive of exposing your QNAP to the world by poking a
hole in your firewall that exposes the QNAP web server?

- Do you want to use a real SSL certificate for your QNAP running
behind a firewall?

- Do you have a custom domain and would like to have something like
`qnap.mycustomdomain.com` going to your qnap?

- Do you have a firewall that's capable of running a Dynamic DNS
service that can update your domain name registrar with its IP
address? (If not, consider using pfSense, OPNsense or something else.)

If so, this solution might work for you.

# What

The setup described here lets you generate a Let's Encrypt signed SSL
certificate for your QNAP system, instead of using the self-signed
certificate used by default on your machine. This solution does not
require you to expose your QNAP to the Internet by opening a port in
your firewall.

# Install git on your QNAP

Unfortunately, Git is not pre-installed on QNAP systems. While there
are multiple ways to install it, I prefer to avoid enabling untrusted
third-party app stores on my NAS.

The simplest way is to run git from Docker container. Just do the following

SSH into your QNAP and become the admin user. Later on you'll need to
run as admin to regenerate the SSL certificates anyway, so you might
as well do it now.


```
mkdir -p ~/bin
cat << 'EOF' >>~/.bashrc
export PATH=$HOME/bin:$PATH
EOF

. ~/.bashrc

cat << 'EOF' >>~/bin/git
#! /bin/sh

docker run -ti --rm -v ${HOME}:/root -v $(pwd):/git alpine/git "$@"
EOF

chmod a+x ~/bin/git
```

This pulls in the alpine/git from https://hub.docker.com/r/alpine/git

The Github repository for it is https://github.com/alpine-docker/git

You now have git installed.

# Create a clone of this repository

To create a clone of this repository decide where you want to place
it. I suggest creating an `src` directory in your admin account:

```
mkdir -p ~/src
cd src
git clone https://github.com/ovidiucp/qnap-letsencrypt
cd qnap-letsencrypt

```


# Setup

0. Decide on the machine name of your QNAP system that you're going to
   use. In the following description I'm going to use
   `qnap.mycustomdomain.com`. I used DreamHost to register my custom
   domain, and I run their own DNS services. As Dynamic DNS provider I
   use DreamHost using their DNS API, so I don't have to pay any extra
   fees for such a service. I use pfSense as my firewall, so if you
   use anything else the terminology might be different.

Create an entry in your firewall's Dynamic DNS service that updates
the DNS settings for your custom domain with the WAN IP address of
your firewall. This is needed because Let's Encrypt will need to look
it up in the process of generating the certificate.

In the DNS Resolver of your firewall add an entry for
`qnap.mycustomdomain.com` that resolves to your QNAP intranet's IP
address. On pfSense this is under `Services / DNS Resolver / General
Settings`, the `Host Overrides` section.

By doing the above steps, any machine on the Internet looking up
`qnap.mycustomdomain.com` will resolve to the public IP address. At the
same time any machine inside your network looking up the same host
will resolve to the intranet IP address of your QNAP system.

1. Ssh into your QNAP system. Just as above let's login as admin since
   it makes life easier.

Create a directory to store the certificate.

```
mkdir /etc/config/apache/ssl
```

Create a directory `~admin/.acme.sh` that will hold the `acme.sh`
installation. This needs to be created in the `admin`'s home
directory, not in the regular QNAP user you logged into.

```
mkdir ~admin/.acme.sh
```

2. Create a `config.txt` file next to this README.md file, containing
the name of the host in your custom domain, and the `acme.sh` settings
to use the custom DNS API for your DNS provider, according to these
instructions.

https://github.com/acmesh-official/acme.sh/wiki/dnsapi

In our example we assume the domain is `mycustomdomain.com`, the name
of the machine `qnap`. If we're using DreamHost, we're going to add a
`DH_API_KEY` with a value obtained from DreamHost's web site.

https://github.com/acmesh-official/acme.sh/wiki/dnsapi#dns_dreamhost

https://help.dreamhost.com/hc/en-us/articles/4407354972692-Connecting-to-the-DreamHost-API

The `config.txt` file would look like this:

```
EMAIL=youremail@yourcustomdomain.com
HOST=qnap.mycustomdomain.com
DNSAPI=dns_dreamhost
DH_API_KEY=XXXXXXXXXXX
```

You can add comments in this file by prefixing them with #. This file
gets passed to the docker executable using the `--env-file` command
line argument. Do not add any shell `export` keywords before the name
of the environment variables, docker parses this file directly and
will complain it sees them.

3. Run the `renew-cert.sh` script with admin priviledges:

```
./renew-certs.sh
```

4. Add `renew-cert.sh` under cron, so that it renews
   automatically. Run it every day, it won't do anything if the
   certificate is not up for renewal.

```
crontab -e
```

In the editor that appear (vi), enter this line:

```
04 11 * * * /share/homes/admin/src/qnap-letsencrypt/renew-certs.sh
```

This runs the renew-certs.sh daily automatically. Change the time when
the script runs if you need to.
