#!/usr/bin/env ruby
## encoding: utf-8

require 'rubygems'
require 'nokogiri'
require 'mechanize'
require 'awesome_print'
require 'optparse'

options = {}
opts = OptionParser.new do |opts|
	opts.banner = 'Usage: '+__FILE__+' [options]'

	opts.on('-v', '--[no-]verbose', 'Run verbosely') do |v|
		options[:verbose] = v
	end

	opts.on('-u', '--username USERNAME', 'Username at account.dyndns.com') do |v|
		options[:username] = v
	end

	opts.on('-p', '--password PASSWORD', 'Password at account.dyndns.com') do |v|
		options[:password] = v
	end
end
opts.parse!

unless options.key?(:username) and options.key?(:password)
	puts opts
	exit(1)
end

msg = ''

agent = Mechanize.new
agent.user_agent_alias = 'Mac Safari' # Pretend to use a Mac

# Start at the login page and log in
page = agent.get('https://account.dyn.com/entrance/')
form = page.forms.first
form['username'] = options[:username]
form['password'] = options[:password]
next_page = form.submit

# TODO: What do we expect to see here?
ngpg = Nokogiri::HTML(next_page.body)
#ap ngpg.css('title')
#collist_last = ngpg.css('div#everything div#everything_content div#sidenav-content.main-content div.col.tre div.collist.last')
#ap collist_last
account_settings = ngpg.css('div#everything div#everything_content div#sidenav-content.main-content div.col.tre div.collist.last h2.nav')
ap account_settings.text if options[:verbose]
# Navigate to the dns area with our free hosts
#next_page = agent.get('https://account.dyn.com/services/')
next_page = agent.get('https://account.dyn.com/dns/dyndns/')

ngpg = Nokogiri::HTML(next_page.body)
dyndnshostnames = ngpg.css('table#dyndnshostnames tr')[2..-1]
ap dyndnshostnames if options[:verbose]

dyndnshostnames.each do |tr|
	td = tr.css('td')
	msg += "#{td[1].text} #{td[3].text}\n"
	#ap td[1].text
	#ap td[3].text
end
#ap dyndnshostnames

=begin
tables = next_page.search('table')
unless tables.nil?
	tables.select { |tbl|
		#pp tbl
		yes = false
		tbl.attributes.each do |atr|
			#pp atr
			if atr[0] == 'id' and atr[1].value == 'dyndnshostnames'
				yes = true
			end
		end
		yes
	}.each do |tag|
		tag.children.each do |child|
			#pp child
		end
	end
end

next_page.search('table#dyndnshostnames').children.each do |a|
  list = a.text.split(/\n+/)
  if list[2].to_s.length > 0 and list[2].to_s !~ /(^Host|^Dyn|^$)/
      msg += "#{list[2]}\n"
  end
end
=end

exec '/usr/local/bin/growlnotify -m "'+msg+'"'
