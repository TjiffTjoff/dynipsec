dynipsec
========

Ruby script to update Loopia DNS and IPsec related settings on Mikrotik

## Usage
ruby dynIP.rb [domain name] [updateMikrotik]

## What it does
The script is intended to run on an interval basis, trigger by preferably cron, to update necessary configuration when a new external IP is provided dynamically from the ISP.

### List domains
If no arguments are given at execution, the script will simple connect to Loopia DNS API and return a list of domain named registered for the given user.

### Update Loopia DNS
When a certain domain name, registered to the user, is given as the first argument, the script will do the following:
* Lookup the current public IP of the host executing the script.
* Lookup the current IP of the domain name (A record for @-entry) from Loopia DNS API.
* Compare public IP with DNS IP.
  * If IPs match; do nothing.
  * If IPs differs; Update the A record for @-entry using Loopa DNS API.

### Update IPsec related configuration on Mikrotik device
When updateMikrotik is appended as a second argument and a difference is detected between the current public IP and the IP from Loopia DNS, the script's functionality is extended with the following:
* Generate a Mikrotik script
* Upload the script over ftp to Mikrotik with file extension .auto.rsc

The .auto.rsc script is automatically executed on Mikrotik when the FTP session is closed, updating the following settings:
* IPsec policies with old IP as sa-src-address and src-address.
* IPsec policies with old IP as sa-dst-address and dst-address.
* GRE interfaces with old IP as local-address.
* Installed IPsec SAs are flushed.
* Existing IPsec remote connections are killed.

## Configuration
At the moment, the configuration has to be done directly in the script file.

_loopiaUsername_ & _loopiaPassword_: Username and password for Loopia DNS API account.  
_mikrotikUsername_ & _mikrotikPassword_: Username and password for Mikrotik user with FTP permissions.
