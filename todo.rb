require "sinatra"
require "sinatra/content_for"
require "bcrypt"
require "yaml"
require "tilt/erubis"
require "pry"
require_relative "database_persistence"

configure do
  enable :sessions
  set :session_secret, "MySessionSecret!2"
  set :erb, :escape_html => true
end

configure(:development) do 
  require "sinatra/reloader" 
  also_reload "database_persistence.rb" 
end 

helpers do
  def list_complete?(list)
    list[:todos_count] > 0 && list[:todos_remaining_count] == 0
  end

  def list_class(list)
    "complete" if list_complete?(list)
  end

  def sort_lists(lists, &block)
    complete_lists, incomplete_lists = lists.partition { |list| list_complete?(list) }

    incomplete_lists.each(&block)
    complete_lists.each(&block)
  end

  def sort_todos(todos, &block)
    complete_todos, incomplete_todos = todos.partition { |todo| todo[:completed] }

    incomplete_todos.each(&block)
    complete_todos.each(&block)
  end
end

def load_list(id)
  list = @storage.find_list(id)
  return list if list

  session[:error] = "The specified list was not found."
  redirect "/lists"
  halt
end

def error_for_list_name(name)
  if !(1..100).cover? name.size
    "List name must be between 1 and 100 characters."
  elsif @storage.all_lists.any? { |list| list[:name] == name }
    "List name must be unique."
  end
end

def error_for_todo(name)
  if !(1..100).cover? name.size
    "Todo must be between 1 and 100 characters."
  end
end

before do
  @username = session[:logged_in] || ""
  @storage = DatabasePersistence.new(logger, @username) 

  if @username
    @lists = @username + "_lists"
    @todos = @username + "_todos"
  end
end

after do
  @storage.disconnect
end

class UsernamePersistence
  attr_accessor :username
  def initialize(username)
    @username = username
  end
end
###################################################### LOGGED OUT ROUTES
post "/signin" do # display signin form
  erb :signin
end

post "/attempt_signin" do 
  @username = params["username"].strip.capitalize 
  @credentials = YAML.load_file(File.expand_path("../data/credentials.yml", __FILE__))
  encrypted_password = @credentials[@username]

  if encrypted_password == params["password"].strip 
    session[:logged_in] = @username
    session[:success] = "Welcome #{@username}."
    redirect "/"

  else
    session[:error] = "Invalid Credentials. Please enter a valid username and password."
    erb :signin 
  end
end

post "/register" do # view register form
  erb :register
end

post "/attempt_register" do 
  @username = params["username"].strip.capitalize
  @password = params["password"]
  @credentials = YAML.load_file(File.expand_path("../data/credentials.yml", __FILE__))

  if @password != params["confirm_password"]
    session[:error] = "Passwords did not match. Please check your spelling and try again."
  elsif [@username, @password].include?""
    session[:error] = "Neither username nor password may be blank."
  elsif @username.include?" "
    session[:error] = "Username may not contain spaces"
  elsif @credentials[@username] || @credentials[@username.delete(' ')] # ' ' 4 table names
    session[:error] = "That username is taken. Please try another one."
  else

    @credentials[@username] = BCrypt::Password.create(params["password"].strip) 
    File.open("data/credentials.yml", "w") { |file| file.write @credentials.to_yaml }
    session[:success] = "You have successfully created a new account."

    session[:logged_in] = @username
    @storage = DatabasePersistence.new(logger, @username) 
    @storage.create_tables
    redirect "/"
  end
  erb :register
end

post "/cancel" do
  redirect "/"
end

########################################################## LOGGED IN ROUTES

post "/signout" do
  session.delete :logged_in
  session[:success] = "You have been signed out"
  redirect "/"
end

get "/" do
  redirect "/lists"
end

get "/lists" do
  @lists = @storage.all_lists if @username != ""
  erb :lists, layout: :layout
end

get "/lists/new" do
  erb :new_list, layout: :layout
end

post "/lists" do
  list_name = params[:list_name].strip

  error = error_for_list_name(list_name)
  if error
    session[:error] = error
    erb :new_list, layout: :layout
  else
    @storage.create_new_list(list_name)
    session[:success] = "The list has been created."
    redirect "/lists"
  end
end

get "/lists/:id" do
  @list_id = params[:id].to_i
  @list = load_list(@list_id)
  @todos = @storage.find_todos_for_list(@list_id)
  erb :list, layout: :layout
end

get "/lists/:id/edit" do
  id = params[:id].to_i
  @list = load_list(id)
  erb :edit_list, layout: :layout
end

post "/lists/:id" do
  list_name = params[:list_name].strip
  id = params[:id].to_i
  @list = load_list(id)

  error = error_for_list_name(list_name)
  if error
    session[:error] = error
    erb :edit_list, layout: :layout
  else
    @storage.update_list_name(id, list_name)
    session[:success] = "The list has been updated."
    redirect "/lists/#{id}"
  end
end

post "/lists/:id/destroy" do
  id = params[:id].to_i
  @storage.delete_list(id)

  session[:success] = "The list has been deleted."
  if env["HTTP_X_REQUESTED_WITH"] == "XMLHttpRequest"
    "/lists"
  else
    redirect "/lists"
  end
end

post "/lists/:list_id/todos" do
  @list_id = params[:list_id].to_i
  @list = load_list(@list_id)
  @todos = @storage.find_todos_for_list(@list_id)
  text = params[:todo].strip

  error = error_for_todo(text)
  if error
    session[:error] = error
    erb :list, layout: :layout
  else
    @storage.create_new_todo(@list_id, text)

    session[:success] = "The todo was added."
    redirect "/lists/#{@list_id}"
  end
end

post "/lists/:list_id/todos/:id/destroy" do
  @list_id = params[:list_id].to_i
  @list = load_list(@list_id)
  todo_id = params[:id].to_i
  @storage.delete_todo_from_list(@list_id, todo_id)

  if env["HTTP_X_REQUESTED_WITH"] == "XMLHttpRequest"
    status 204
  else
    session[:success] = "The todo has been deleted."
    redirect "/lists/#{@list_id}"
  end
end

post "/lists/:list_id/todos/:id" do
  @list_id = params[:list_id].to_i
  @list = load_list(@list_id)

  todo_id = params[:id].to_i
  is_completed = params[:completed] == "true"
  @storage.update_todo_status(@list_id, todo_id, is_completed)

  session[:success] = "The todo has been updated."
  redirect "/lists/#{@list_id}"
end

post "/lists/:id/complete_all" do
  @list_id = params[:id].to_i
  @list = load_list(@list_id)

  @storage.mark_all_todos_as_completed(@list_id)

  session[:success] = "All todos have been completed."
  redirect "/lists/#{@list_id}"
end

