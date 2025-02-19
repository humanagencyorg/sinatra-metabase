require 'sinatra'
require 'jwt'
require 'json'
require 'dotenv/load'

# Enable sessions so we can store authentication state
enable :sessions

set :public_folder, 'public'

# Read environment variables
METABASE_SITE_URL    = ENV['METABASE_SITE_URL']
METABASE_SECRET_KEY  = ENV['METABASE_SECRET_KEY']
APP_PASSWORD         = ENV['APP_PASSWORD']

# Helper method to generate the iframe URL
def generate_iframe_url
  payload = {
    resource: { dashboard: 2 },
    params: {},
    exp: Time.now.to_i + (60 * 10)  # Token expires in 10 minutes
  }
  
  token = JWT.encode(payload, METABASE_SECRET_KEY)
  "#{METABASE_SITE_URL}/embed/dashboard/#{token}#bordered=true&titled=true"
end

# Show a simple login form if the user is not authenticated
get '/' do
  if session[:authenticated]
    redirect '/display'
  else
    erb :login
  end
end

# Handle login form submission
post '/login' do
  if params[:password] == APP_PASSWORD
    session[:authenticated] = true
    redirect '/display'
  else
    @error = "Invalid password."
    erb :login
  end
end

# Protected route: Only show if user is authenticated
get '/display' do
  redirect '/' unless session[:authenticated]

  @iframe_url = generate_iframe_url
  erb :display
end

# If you still want to provide an endpoint returning JSON:
get '/iframe_url' do
  redirect '/' unless session[:authenticated]

  content_type :json
  { iframe_url: generate_iframe_url }.to_json
end

# Optional logout route
get '/logout' do
  session.clear
  redirect '/'
end

