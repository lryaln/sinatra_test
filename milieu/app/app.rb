require 'sinatra'
require './helpers/sinatra'
require './helpers/milieu'
require './model/mongodb'
require 'haml'
require 'digest/md5'
require 'googlestaticmap'


configure do
  enable :sessions
end

# This runs prior to all requests.
# It passes along the logged in user's object (from the session)
before do
  unless session[:user] == nil
    @suser = session[:user]
  end
end

get '/' do
  haml :index
end

get '/login' do
  haml :login
end

# The login post routine will take the provided params and run the auth routine.
# If the auth routine is successful it will return the user object, else nil
post '/login' do
  if session[:user] = User.auth(params["email"], params["password"])
    flash("Login successful")
    redirect "/user/" << session[:user].email << "/dashboard"
  else
    flash("Login failed - Try again")
    redirect '/login'
  end
end

get '/logout' do
  session[:user] = nil
  flash("Logout successful")
  redirect '/'
end

get '/register' do
  haml :register
end

post '/register' do
  # Creating and populating a new user object from the DB
  u            = User.new
  u.email      = params[:email]
  u.password   = params[:password]
  u.name       = params[:name]

  # Attempt to save the user to the DB
  if u.save()
    flash("User created")

    # If user saved, authenticate from the database
    session[:user] = User.auth( params["email"], params["password"])
    redirect '/user/' << session[:user].email.to_s << "/dashboard"
  else
    # Else, display errors
    tmp = []
    u.errors.each do |e|
      tmp << (e.join("<br/>"))
    end
    flash(tmp)
    redirect '/create'
  end
end

get '/user/:email/dashboard' do
  haml :user_dashboard
end

get '/user' do
  if logged_in?
      redirect '/user/' + session[:user].email + '/profile'
  else
      redirect '/'
  end
end

get '/user/:email/profile' do
  @user = User.new_from_email(params[:email])
  haml :user_profile
end

get '/venues' do
  @page = 1
  @total_pages = 1
  @venues = VENUES.find
  haml :venues
end


get '/venues/?:page?' do
  @page = params.fetch('page',1).to_i
  pp = 10
  @venues = VENUES.find.skip( (@page - 1) * pp ).limit(pp)
  @total_pages = (VENUES.count.to_i / pp).ceil
  haml :venues
end


get '/venue/:_id' do
  # Code to show a single venue goes here
  object_id = BSON::ObjectId.from_string(params[:_id])
  @venue = VENUES.find_one({ :_id => object_id })
  @nearby_venues = VENUES.find({ :'location.geo' => { :$near => [ @venue['location']['geo'][0], @venue['location']['geo'][1]]}}).limit(4).skip(1)
  haml :venue
end


get '/venue/:_id/checkin' do
    # Code to check-in to a venue goes here
end



