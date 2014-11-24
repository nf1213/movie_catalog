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
  random = 0
  @movies = movies_from_db_to_hash
  while !@movies.has_key?(random.to_s) do
    random = rand(@movies.size).round
  end
  random
end

def movies_from_db
  movies = db_connection do |conn|
    conn.exec('SELECT movies.id, movies.title, movies.year, movies.synopsis, movies.rating, genres.name AS genre, studios.name AS studio FROM movies JOIN genres ON genres.id = movies.genre_id JOIN studios ON movies.studio_id = studios.id ORDER BY movies.title')
  end
end

def movies_from_db_to_hash
  movies_array = movies_from_db.to_a
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
  id = params[:id]
  @movies = movies_from_db_to_hash
  @movie = @movies[id]
  @letters = 'a'.upto('z').to_a
  @random = random_number
  erb :show
end

get '/' do
  redirect '/movies'
end
