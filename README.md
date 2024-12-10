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

1. Ssh into your QNAP system. These instructions assume you log in as
   a regular user in QNAP, not as an admin. Howewer this regular user
   must have the ability to `sudo` as the `admin` user (QNAP uses
   `admin` as opposed to the more common `root` user on Linux.

Create a directory to store the certificate.

```
sudo mkdir /etc/config/apache/ssl
```

Create a directory `~admin/.acme.sh` that will hold the `acme.sh`
installation. This needs to be created in the `admin`'s home
directory, not in the regular QNAP user you logged into.

```
sudo mkdir ~admin/.acme.sh
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
sudo ./renew-certs.sh
```

4. Add `renew-cert.sh` under cron, so that it renews
   automatically. Run it every day, it won't do anything if the
   certificate is not up for renewal.
