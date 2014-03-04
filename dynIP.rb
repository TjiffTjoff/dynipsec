#!/usr/local/bin/ruby

require 'xmlrpc/client'
require 'uri'
require 'net/http'
require 'net/ftp'

#Credentials for Loopia DNS API
loopiaUsername = 'registered_api_username@loopiaapi'
loopiaPassword = 'registered_api_password'
mikrotikUsername = 'mikrotik_ftp_username'
mikrotikPassword = 'mikrotik_ftp_password'

global_domain_server_url = "https://api.loopia.se/RPCSERV"

client = XMLRPC::Client.new2(global_domain_server_url)

#If no arguments are provided the script lists registered domain names
if ARGV.empty?
  response = client.call("getDomains", loopiaUsername, loopiaPassword)
  response.each do |r|
    puts r['domain']
  end
else
  #Get external IP of the current host
  url = URI('http://www.myexternalip.com/raw')
  extip = Net::HTTP.get(url).strip
  
  #Get record ID and IP of A record for @ (root domain) 
  records = client.call("getZoneRecords", username, password, ARGV[0], "@")
  records.each do |r|
    @arecord = r['record_id'] if r['type'] == "A"
    @dnsip = r['rdata'] if r['type'] == "A"
  end

  if extip == @dnsip
    system("logger -t LoopiaDns 'External IP is the same as current DNS IP, exiting'")
  else
    #If updateMikrotik is appended as a second argument, an update script is generated and uploaded to Mikrotik
    if ARGV[1] == "updateMikrotik"
      #Generate script to update existing IPsec policies and GRE interfaces with the new IP
      file = File.open("/srv/newip.auto.rsc", "w+")
      file.write("/log info \"Updating ipsec with new IP\"\n")
      file.write("/ip ipsec policy set src-address=#{extip}/32 sa-src-address=#{extip} [ find src-address=#{@dnsip}/32 ]\n")
      file.write("/ip ipsec policy set dst-address=#{extip}/32 sa-dst-address=#{extip} [ find dst-address=#{@dnsip}/32 ]\n")
      file.write("/log info \"Done updating ipsec\"\n")
      file.write("/log info \"Updating gre tunnels with new IP\"\n")
      file.write("/interface gre set local-address=#{extip} [ find local-address=#{@dnsip} ]\n")
      file.write("/log info \"Done updating gre tunnels\"\n")
      file.write("/log info \"Killing current IPsec connections\"\n")
      file.write("/ip ipsec remote-peers kill-connections\"\n")
      file.write("/log info \"Flushing installed SA\"\n")
      file.write("/ip ipsec installed-sa flush\"\n")
      file.close

      #Upload script to mikrotik device for automatic execution
      ftp = Net::FTP.new('url_to_mikrotik')
      ftp.login(mikrotikUsername, mikrotikPassword)
      ftp.puttextfile("/srv/updateIpsec.auto.rsc")
      ftp.close

      system("logger -t LoopiaDns 'Updating IPsec related settings on Mikrotik'")
    end

    #Update the A record for @ (root domain) with new IP
    record = { 'type' => 'A', 'ttl' => 600, 'rdata' => "#{ip.strip}", 'record_id' => @arecord, 'priority' => 1 } 
    response = client.call("updateZoneRecord", username, password, ARGV[0], "@", record)
    system("logger -t LoopiaDns 'Updating #{ARGV[0]}: #{response.inspect}'")
  end

end
