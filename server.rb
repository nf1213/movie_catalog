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

def find_random_movie
  sql = %{
    SELECT movies.id, movies.title, movies.year, movies.synopsis,
    movies.rating, genres.name AS genre, studios.name AS studio FROM movies
    JOIN genres ON genres.id = movies.genre_id
    JOIN studios ON movies.studio_id = studios.id
    ORDER BY RANDOM() LIMIT 1
  }
  movie = db_connection do |db|
    db.exec(sql)
  end
  movie.to_a.first
end

def find_movie_by_id(id)
  sql = %{
    SELECT movies.id, movies.title, movies.year, movies.synopsis,
    movies.rating, genres.name AS genre, studios.name AS studio FROM movies
    JOIN genres ON genres.id = movies.genre_id
    JOIN studios ON movies.studio_id = studios.id
    WHERE movies.id = $1 ORDER BY movies.title
  }
  movie = db_connection do |db|
    db.exec_params(sql, [id])
  end
  movie.to_a.first
end

def find_movies_by_title(string)
  sql = %{
    SELECT title, id FROM movies
    WHERE title ILIKE '%#{string}%' ORDER BY title
  }
  movies = db_connection do |db|
    db.exec(sql)
  end
  movies.to_a
end

def find_movies_starting_with(string)
  sql = %{
    SELECT title, id FROM movies
    WHERE title ILIKE '#{string}%' ORDER BY title
  }
  movies = db_connection do |db|
    db.exec(sql)
  end
  movies.to_a
end

def movie_titles_and_ids
  sql = 'SELECT title, id FROM movies ORDER BY title'
  movies = db_connection do |db|
    db.exec(sql)
  end
  movies.to_a
end

get '/movies' do
  @movies = movie_titles_and_ids
  @letters = 'a'.upto('z').to_a
  erb :index
end

get '/search/' do
  @search = params[:query]
  @search.gsub!(" ", "+")
  redirect "/filter/#{@search}"
end

get '/filter/:filter' do
  @letters = 'a'.upto('z').to_a
  filter = params[:filter]
  filter.gsub!("+", " ")
  if filter.length == 1
    @movies = find_movies_starting_with(filter)
  else
    @movies = find_movies_by_title(filter)
  end
  erb :index
end

get '/random' do
  @letters = @letters = 'a'.upto('z').to_a
  @movie = find_random_movie
  erb :show
end

get '/filter/' do
  redirect '/movies'
end

get '/movies/:id' do
  id = params[:id]
  @movie = find_movie_by_id(id)
  @letters = 'a'.upto('z').to_a
  erb :show
end

get '/' do
  redirect '/movies'
end
