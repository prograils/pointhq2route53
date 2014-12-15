#!/usr/bin/env ruby

## setup bundler
require 'rubygems'
require 'bundler/setup'
Bundler.require(:default)
require 'point'
require 'awesome_print'
require 'route53'

Point.username = ENV['POINTHQ_USERNAME']
Point.apitoken = ENV['POINTHQ_APITOKEN']

route53 = Route53::Connection.new(ENV['ROUTE53_ACCESS_KEY'],
                                  ENV['ROUTE53_SECRET_KEY'])
point_zones = Point::Zone.find(:all)
route53_zones = route53.get_zones

if ENV['ROUTE53_DELETE_ZONES']
  puts 'Deleting AWS zones...'
  route53_zones.each do |zone|
    puts "\t deleting #{zone.name}"
    zone.get_records.each do |record|
      record.delete if record.type != 'NS' && record.type != 'SOA'
    end
    resp = zone.delete_zone
    while resp.pending?
      sleep 1
    end
  end
  route53_zones = route53.get_zones
end

point_zones.each do |zone|
  puts zone.name
  in_route = route53_zones.select{|z| z.name.downcase[0...-1] == zone.name.downcase}
  if in_route.empty?
    puts "\tmigrating records to Route53"
    zone_data = {}
    zone.records.each do |record|
      record_key = "#{record.name}-#{record.record_type}"
      zone_data[record_key] ||= {}
      zone_data[record_key]['name'] ||= record.name
      zone_data[record_key]['record_type'] ||= record.record_type
      zone_data[record_key]['ttl'] ||= record.ttl
      zone_data[record_key]['data'] ||= []
      data = record.data.downcase
      data = 'alt3.aspmx.l.google.com.' if data == 'aspmx2.googlemail.com.'
      data = 'alt4.aspmx.l.google.com.' if data == 'aspmx3.googlemail.com.'
      data = "#{record.aux} #{data}" if record.record_type == 'MX'
      next if data == 'aspmx4.googlemail.com.'
      next if data == 'aspmx5.googlemail.com.'
      zone_data[record_key]['data'] << data
    end
    # if zone.name == 'where2moto.com'
    # ap zone.records
    # ap zone_data
    # end
    puts "\tcreating aws zone..."
    new_zone = Route53::Zone.new("#{zone.name}.", nil, route53)
    resp = new_zone.create_zone
    next if resp.error?
    while resp.pending?
      sleep 1
    end
    puts "\tmigrating records"
    zone_data.each do |k, record|
      puts "\tcreating record for #{k}"
      new_record = Route53::DNSRecord.new(record['name'],
                                          record['record_type'].upcase,
                                          record['ttl'],
                                          record['data'],
                                          new_zone)
      resp = new_record.create
    end
  else
    puts "\texists in Route53, skipping"
  end
  puts ''
end

