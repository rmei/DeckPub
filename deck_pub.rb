require 'sinatra'
require 'deck'

get '/fetch' do # gettin stuffs fro dropbox
  "<html><head/><body>Halo, whirled.</body></html>"

=begin
  commit_json = JSON.parse(CGI.unescape(params["payload"]))

  if commit_json["ref"] != "refs/heads/master"
    puts "Got notification of a non-master commit (#{commit_json["ref"]}) - ignoring."
    return
  end

  commit_details = []
  authors = []

  commit_json["commits"].each do |commit|
    authors << commit["author"]["name"]
    api_url = "http://github.com/api/v2/json/commits/show/#{repo}/#{commit['id']}"
    details = JSON.parse(`curl #{api_url}`)["commit"]
    details["diff_url"] = commit["url"]
    commit_details << details
  end

  Pony.mail(
    :to => list_address,
    :via => :smtp,
    :via_options => {
      :address => 'smtp.gmail.com',
      :port => '587',
      :enable_starttls_auto => true,
      :user_name => gmail_user_name,
      :password => gmail_password,
      :authentication => :plain,
      :domain => "HELO" # why?
    },
    :subject => "#{authors.uniq.join(', ')} committed to master at #{repo}",
    :body => erb(:email, :locals => {:commit_details => commit_details})
  )
=end

end

get '/up' do
  "<html><head/><body>Yup.</body></html>"
end

