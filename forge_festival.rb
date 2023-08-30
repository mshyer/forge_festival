require "sinatra"

require "tilt/erubis"
require "sinatra/content_for"
require "yaml"
require "bcrypt"
require "pg"
require_relative 'database_persistence'
require_relative 'validation'
include Validator

begin
  connection = PG.connect(dbname: "forge_festival")
rescue PG::ConnectionBad
  puts "CREATING DATABASE"
  `createdb forge_festival`
  puts "INITIALIZING DATABASE"
  `psql -d forge_festival < forge_festival.sql`
end

def users_path
  File.expand_path('users', __dir__)
end

def logged_in?
  session[:user] && session[:user] != ""
end

def require_login
  return if logged_in?
  session[:error] = ["Please Log In"]
  session[:url_hop] = request.url
  redirect "/login"
end

def login(username)
  session[:user] = username
end

def logout
  session.delete(:user)
end

helpers do
  def user?
    user = session[:user].to_sym if session[:user]
    @users[:users].keys.include?(user)
  end

  def page(param)
    if param == "" || !param
      1
    else
      param.to_i
    end
  end
end

configure(:development) do
  require "sinatra/reloader"
  after_reload do
    puts "reloaded"
  end
end

configure do
  enable :sessions
  set :session_secret, 'c762eabfeb73461ed6daf1ab63d117c7f3c02ddf4f10a2d5c6c1560e517db061'
  set :erb, escape_html: true
end

before do
  @database = DatabasePersistence.new(PG.connect(dbname: "forge_festival"))
  @users = YAML.load_file("#{users_path}/users.yaml")
end

after do
  @database&.close
end

# Login routes

get "/login" do
  erb :login, layout: :layout
end

post "/login" do
  @url_hop = session[:url_hop]
  @username = params[:username]
  @password = params[:password]
  error = validate(:credentials)
  if error != []
    session[:error] = error
    p session[:error]
    erb :login, layout: :layout
  else
    session[:success] = "logged in successfully!"
    login(@username)
    redirect @url_hop if @url_hop
    redirect "/"
  end
end

post "/logout" do
  logout
  session[:success] = "Logged out successfully."
  redirect "/"
end

# Home / about

get "/" do
  @page = page(params[:page])
  @num_pages = @database.calculate_team_pages
  validate_url_params(:rankings_page_number) if params[:page]
  @forge_teams = @database.forge_teams(@page)
  erb :about, layout: :layout
end

get "/about" do
  erb :about, layout: :layout
end

# team rankings screen

get "/rankings" do
  require_login
  @page = page(params[:page])
  @num_pages = @database.calculate_team_pages
  validate_url_params(:rankings_page_number) if params[:page]
  @forge_teams = @database.forge_teams(@page)
  erb :rankings, layout: :layout
end

# Forge team summary page

get "/forge-team/:forge_team_id" do
  require_login
  @forge_team_id = params[:forge_team_id]
  validate_url_params(:forge_team_id)
  validate_url_params(:items_page_number) if params[:page]

  @forge_team = @database.forge_team(@forge_team_id)
  @page = page(params[:page])
  @num_pages = @database.calculate_item_pages(@forge_team_id)
  @items = @database.items(@forge_team_id, @page)
  erb :forge_team, layout: :layout
end

# Create and edit forge team routes

get "/forge-teams/new" do
  require_login
  erb :new_forge_team, layout: :layout
end

post "/forge-teams/new" do
  require_login
  @team_name = params[:team_name]
  @region = params[:region]
  @team_leader = params[:team_leader]
  error = validate(:team_name, :region, :team_leader)
  if !error.empty?
    session[:error] = error
    erb :new_forge_team, layout: :layout
  else
    @database.create_new_team(@team_name, @region, @team_leader)
    redirect "/rankings"
  end
end

get "/forge-team/:forge_team_id/edit" do
  require_login
  validate_url_params(:forge_team_id)
  @forge_team_id = params[:forge_team_id]
  @forge_team = @database.forge_team(@forge_team_id)
  @original_team_name = @forge_team["team_name"]
  @team_name = @forge_team["team_name"]
  @region = @forge_team["region"]
  @team_leader = @forge_team["team_leader"]

  erb :edit_forge_team, layout: :layout
end

post "/forge-team/:forge_team_id/edit" do
  validate_url_params(:forge_team_id)
  @forge_team_id = params[:forge_team_id]
  @forge_team = @database.forge_team(@forge_team_id)

  @original_team_name = @forge_team["team_name"]
  original_region = @forge_team["region"]
  original_team_leader = @forge_team["team_leader"]

  @team_name = params[:team_name]
  @region = params[:region]
  @team_leader = params[:team_leader]

  validations = []
  validations << :team_name unless @original_team_name.downcase == @team_name.downcase
  validations << :region unless original_region.downcase == @region.downcase
  validations << :team_leader unless original_team_leader.downcase == @team_leader.downcase

  error = validate(*validations)
  if !error.empty?
    session[:error] = error
    erb :edit_forge_team, layout: :layout
  else
    @database.update_team_info(@forge_team_id, @team_name, @region, @team_leader)
    redirect "/forge-team/#{@forge_team_id}"
  end
end

# Create and edit item routes

get "/forge-team/:forge_team_id/items/new" do
  require_login
  validate_url_params(:forge_team_id)
  @forge_team_id = params[:forge_team_id]
  @forge_team = @database.forge_team(@forge_team_id)
  erb :new_item, layout: :layout
end

post "/forge-team/:forge_team_id/items/new" do
  validate_url_params(:forge_team_id)
  @forge_team_id = params[:forge_team_id]
  @forge_team = @database.forge_team(@forge_team_id)
  @item_name = params[:item_name]
  @type = params[:type]
  @quality = params[:quality]
  @beauty = params[:beauty]
  error = validate(:item_forge_team_id, :item_name, :type, :quality, :beauty)
  if !error.empty?
    session[:error] = error
    erb :new_item, layout: :layout
  else
    @database.add_team_item(@forge_team_id, @item_name, @type, @quality, @beauty)
    redirect "/forge-team/#{@forge_team_id}"
  end
end

get "/forge-team/:forge_team_id/item/:item_id/edit" do
  require_login
  @forge_team_id = params[:forge_team_id]
  validate_url_params(:forge_team_id, :item_id)
  @forge_team = @database.forge_team(@forge_team_id)
  @item_id = params[:item_id]
  @item = @database.item(@item_id)

  @original_item_name = @item["item_name"]
  @item_name = @item["item_name"]
  @type = @item["type"]
  @quality = @item["quality"]
  @beauty = @item["beauty"]
  erb :edit_item, layout: :layout
end

post "/forge-team/:forge_team_id/item/:item_id/edit" do
  validate_url_params(:forge_team_id, :item_id)
  @forge_team_id = params[:forge_team_id]
  @forge_team = @database.forge_team(@forge_team_id)
  @item_id = params[:item_id]
  @item = @database.item(@item_id)

  @original_item_name = @item["item_name"]
  original_type = @item["type"]
  original_quality = @item["quality"]
  original_beauty = @item["beauty"]

  @item_name = params["item_name"]
  @type = params["type"]
  @quality = params["quality"]
  @beauty = params["beauty"]

  validations = []
  validations << :item_name unless @original_item_name.downcase == @item_name.downcase
  validations << :type unless original_type.downcase == @type.downcase
  validations << :quality unless original_quality == @quality
  validations << :beauty unless original_beauty == @beauty

  error = validate(*validations)
  if !error.empty?
    session[:error] = error
    erb :edit_item, layout: :layout
  else
    @database.update_item_info(@item_id, @item_name, @type, @quality, @beauty)
    redirect "/forge-team/#{@forge_team_id}"
  end
end

# delete items and forge teams routes

post "/forge-team/:forge_team_id/item/:item_id/delete" do
  validate_url_params(:forge_team_id, :item_id)
  item_id = params[:item_id]
  forge_team_id = params[:forge_team_id]
  @database.delete_item(item_id)
  redirect "/forge-team/#{forge_team_id}"
end

post "/forge-team/:forge_team_id/delete" do
  validate_url_params(:forge_team_id)
  forge_team_id = params[:forge_team_id]
  @database.delete_forge_team(forge_team_id)
  redirect "/rankings"
end

not_found do
  session[:error] = ["Page Not Found"]
  erb :home, layout: :layout
end
