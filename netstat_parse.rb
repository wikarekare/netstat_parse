#!/usr/local/bin/ruby
require 'rubygems'
require 'geoip'
require 'socket'
require 'resolv-replace'
require 'pp'

#Find out who is connected to this host, and from where in the world.

#Data from maxmind.com . Update monthly
GEODB = '/usr/local/wikk/etc/geoip/GeoLiteCity.dat'

#Reverse lookup of DNS name
def resolve_name(a)
  begin
    Resolv.getname(a)
  rescue Resolv::ResolvError
    return a
  end
end

def row_to_s(row, src_t, dest_t, location)
  "%4.4s %8.8s %8.8s %32.32s:%-8.8s %32.32s:%-8.8s    %s" % [row[0], row[1], row[2], resolve_name(src_t[0]),src_t[1], resolve_name(dest_t[0]), dest_t[1], location ]
end
  

o = `netstat -an` #Netstat command to run

o.split("\n").each do |l|
  tokens = l.squeeze(' ').split(' ')
  if tokens[5] == "ESTABLISHED"
    src_t = tokens[3].split(':')
    dest_t = tokens[4].split(':')
    if src_t.length == 1
      src_t = tokens[3].split('.')
      src_t = ["#{src_t[0]}.#{src_t[1]}.#{src_t[2]}.#{src_t[3]}", src_t[4]]
      dest_t = tokens[4].split('.')
      dest_t = ["#{dest_t[0]}.#{dest_t[1]}.#{dest_t[2]}.#{dest_t[3]}", dest_t[4]]
    end
=begin
    if tokens[0] =~ /^udp.*/
      src = Addrinfo.udp(*src_t).getnameinfo.join(':')
      dest = Addrinfo.udp(*dest_t).getnameinfo.join(':')
    elsif  tokens[0] =~ /^tcp.*/
      src = Addrinfo.tcp(*src_t).getnameinfo.join(':')
      dest = Addrinfo.tcp(*dest_t).getnameinfo.join(':')
    else
      src = tokens[3]
      dest = tokens[4]
    end
=end
    
    external_ip = dest_t[0]
    if external_ip =~ /10\..*/ || external_ip =~ /192\.168\..*/
      puts row_to_s(tokens,src_t,dest_t,"Wikarekare")
    elsif external_ip =~ /127\..*/ || external_ip == 'localhost'
      puts row_to_s(tokens,src_t,dest_t, "Localhost")
    elsif external_ip.index('.') == nil
      puts row_to_s(tokens,src_t,dest_t, "Local")
    else
      begin
        c = GeoIP.new(GEODB).city(external_ip)
      rescue SocketError
        c = nil
      end
      if c == nil
        puts row_to_s(tokens ,src_t,dest_t, "UNKNOWN")
      else
        puts row_to_s(tokens ,src_t,dest_t, "#{c.city_name} #{c.country_name}")
      end
    end
  end
end
