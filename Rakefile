task :default => :local

# jekyll local test, kill jekyll
task :kill do
	`ps aux | grep "[j]ekyll" | tr -s ' ' | cut -d " " -f 2 | xargs kill -9`
end

task :build do
	system("jekyll")
end

# Refreshes the web page in Firefox
task :local => :build do
	puts %x[rsync -q -acvrz	 --delete _site/]
	# %x[osascript -e 'open location "http://localhost/"']
	%x[
		# Check if Firefox is running, if so refresh
		ps -xc|grep -sqi firefox && osascript <<'APPLESCRIPT'
			 tell app "Firefox" to activate
			 tell app "System Events"
					if UI elements enabled then
						 keystroke "r" using command down
						 -- Fails if System Preferences > Universal access > "Enable access for assistive devices" is not on 
					--else
						 --tell app "Firefox" to Get URL "JavaScript:window.location.reload();" inside window 1
						 -- Fails if Firefox is set to open URLs from external apps in new tabs.
					end if
			 end tell
		APPLESCRIPT 
	]
end

# Commit the changes to the site.
task :commit => :build do
	puts %x[rsync -q -acvrz --exclude .git --delete _site/ _compiled/]
	puts %x[./compress.rb]
	puts %x[cd _compiled; git add .; git commit -am "`date +%F_%H-%M_%s`"; ]
end

task :send => [:remove_cache, :ssend] do
	
end

# Send the changes to the server and open the webpage
task :ssend => :commit do
	puts %x[cd _compiled; git push origin master]
end



task :remove_cache do
	`rm _cache/*`
end

# Makes a new post
task :new do
	throw "No title given" unless ARGV[1]
	title = ""
	ARGV[1..ARGV.length - 1].each { |v| title += " #{v}" }
	title.strip!
	now = Time.now
	path = "_posts/#{now.strftime('%F')}-#{title.downcase.gsub(/[\s\.]/, '-').gsub(/[^\w\d\-]/, '')}.md"
	
	File.open(path, "w") do |f|
		f.puts "---"
		f.puts "layout: post"
		f.puts "title: #{title}"
		f.puts "date: #{now.strftime('%F %T')}"
		f.puts "category: "
		f.puts "tags:"
		f.puts " - "
		f.puts "---"
		f.puts ""
		f.puts ""
	end
	
	`mate #{path}`
	exit
end

task :css do
	require "sass"
	contents = IO.read("css/site.scss").gsub(/^\-{3}\n.*?\-{3}/, "")
	
	File.open("_site/site.css", "w") do |f|
		f.write Sass::Engine.new(contents, :syntax => :scss, :style => :compressed).render
	end
end
