require 'rubygems'
require 'sinatra'
require 'json'
require 'open-uri'
require 'net/http'

# Receive a post-commit hook
post '/' do
  push = JSON.parse(params[:payload])
  push[:commits].each do |commit|
    # Scan the commit, create issues if necessary
    diff = 
      URI.parse("#{push[:repository][:url]}/commit/#{commit[:id]}.diff").read
    
    file = ''

    diff.each_line do |line|
      if line[0...4] == 'diff'
        # I think it would be escaped if there was a dir called this b/
        file = line.split(' b/')[-1]

      # don't grab +++ 
      elsif line[0...1] == '+ '
        if line.index('TODO').nil? == false
          # Create an issue
          # First try with :
          title = line.split('TODO:')[-1]
          if title.nil?
            title = line.split('TODO')[-1]
          end

          body = "in #{file}:\n#{line}\nFirst appeared in #{commit[:id]}"
          data = {
            :title => title,
            :body => body,
            # Assign to committer
            :assignee => commit[:author][:name],
            :labels => ['todo']
          }

          url = 'https://api.github.com/repos/#{commit[:repository][:owner][:name]}/#{commit[:repository][:name]}/issues'
          puts "Posting to #{url} with #{data}"

          Net::HTTP.post_form(URI.parse(url), data)

        end
      end
    end
  end
end

get '/' do
  "This app does not support GET access. Add the current URL to your git post-receive hooks."
end
