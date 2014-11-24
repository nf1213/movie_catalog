require 'sinatra'
require 'sinatra/reloader'
require 'pg'

def db_connection
  begin
    connection = PG.connect(dbname: 'movies')

    yield(connection)

  ensure
    connection.close
  end
end

def random_number
  count = db_connection do |conn|
    conn.exec('SELECT count(*) FROM movies')
  end
  count = count[0]['count'].to_i
  random = rand(count).round
end

def movies_from_db
  movies = db_connection do |conn|
    conn.exec('SELECT * FROM movies ORDER BY title')
  end
end

def movies_from_db_to_hash
  movies_array = movies_from_db
  hash = {}

  movies_array.each do |movie|
    hash[movie['id']] = movie
  end
  hash
end

get '/movies' do
  @movies = movies_from_db_to_hash
  @letters = 'a'.upto('z').to_a
  @random = random_number
  erb :index
end

get '/search/' do
  @search = params[:query]
  redirect "/filter/#{@search}"
end

get '/filter/:filter' do
  @letters = 'a'.upto('z').to_a
  @movies = movies_from_db_to_hash
  @filter = params[:filter]
  @random = random_number
  erb :index
end

get '/filter/' do
  redirect '/movies'
end

get '/movies/:id' do
  id = params[:id].to_i
  @movies = movies_from_db_to_hash
  @movie = db_connection do |conn|
    conn.exec("SELECT * FROM movies WHERE id = #{id}")
  end
  @movie = @movie.to_a[0]
  @letters = 'a'.upto('z').to_a
  @random = random_number
  erb :show
end

get '/' do
  redirect '/movies'
end
