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
    SELECT movies.title, movies.year, movies.synopsis,
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

def find_actor_by_id(id)
  sql = %{
    SELECT movies.title, cast_members.character, movies.id FROM actors
    JOIN cast_members ON cast_members.actor_id = actors.id
    JOIN movies ON cast_members.movie_id = movies.id
    WHERE actors.id = $1 ORDER BY movies.title
  }
  actor = db_connection do |db|
    db.exec_params(sql, [id])
  end
  actor.to_a
end

def find_actor_name_by_id(id)
  sql = %{
    SELECT name FROM actors
    WHERE id = $1
  }
  name = db_connection do |db|
    db.exec_params(sql, [id])
  end
  name.to_a[0]['name']
end

def find_movies_by_title(string)
  sql = %{SELECT movies.title, movies.year, movies.rating,
    genres.name AS genre, studios.name AS studio, movies.id FROM movies
    JOIN genres ON movies.genre_id = genres.id
    JOIN studios ON movies.studio_id = studios.id
    WHERE title ILIKE '%#{string}%'
    ORDER BY title
  }
  movies = db_connection do |db|
    db.exec(sql)
  end
  movies.to_a
end

def find_actors_by_title(string)
  sql = %{
    SELECT name, id FROM actors
    WHERE name ILIKE '%#{string}%' ORDER BY name
  }
  movies = db_connection do |db|
    db.exec(sql)
  end
  movies.to_a
end

def find_movies_starting_with(let)
  sql = %{SELECT movies.title, movies.year, movies.rating,
    genres.name AS genre, studios.name AS studio, movies.id FROM movies
    JOIN genres ON movies.genre_id = genres.id
    JOIN studios ON movies.studio_id = studios.id
    WHERE title ILIKE '#{let}%'
    ORDER BY title
  }
  movies = db_connection do |db|
    db.exec(sql)
  end
  movies.to_a
end

def find_actors_starting_with(let)
  sql = %{
    SELECT name, id FROM actors
    WHERE name ILIKE '#{let}%' ORDER BY name
  }
  actors = db_connection do |db|
    db.exec(sql)
  end
  actors.to_a
end

def find_movies
  sql = 'SELECT movies.title, movies.year, movies.rating,
  genres.name AS genre, studios.name AS studio, movies.id FROM movies
  JOIN genres ON movies.genre_id = genres.id
  JOIN studios ON movies.studio_id = studios.id
  ORDER BY title'
  movies = db_connection do |db|
    db.exec(sql)
  end
  movies.to_a
end

def actor_names_and_ids
  sql = 'SELECT name, id FROM actors ORDER BY name'
  actors = db_connection do |db|
    db.exec(sql)
  end
  actors.to_a
end

def find_actors_by_movie(id)
  sql = %{
    SELECT actors.name, cast_members.character, actors.id FROM cast_members
    JOIN movies ON cast_members.movie_id = movies.id
    JOIN actors ON cast_members.actor_id = actors.id
    WHERE movies.id = #{id}
    ORDER BY title
  }
  actors = db_connection do |db|
    db.exec(sql)
  end
  actors.to_a
end

get '/movies' do
  @movies = find_movies
  @letters = 'a'.upto('z').to_a
  erb :'movies/index'
end

get '/actors' do
  @actors = actor_names_and_ids
  @letters = 'a'.upto('z').to_a
  erb :'actors/index'
end

get '/actors/filter/:filter' do
  @letters = 'a'.upto('z').to_a
  filter = params[:filter]
  filter.gsub!("+", " ")

  if filter.length == 1
    @actors = find_actors_starting_with(filter)
  else
    @actors = find_actors_by_title(filter)
  end

  erb :'actors/index'
end

get '/actors/:id' do
  @letters = 'a'.upto('z').to_a
  id = params[:id]
  @actor = find_actor_by_id(id)
  @name = find_actor_name_by_id(id)
  erb :'actors/show'
end

get '/search/' do
  @search = params[:query]
  @search.gsub!(" ", "+")

  if params[:select] == "movies"
    redirect "/filter/#{@search}"
  else
    redirect "/actors/filter/#{@search}"
  end
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

  erb :'movies/index'
end

get '/random' do
  @letters = @letters = 'a'.upto('z').to_a
  @movie = find_random_movie
  id = @movie['id']
  @actors = find_actors_by_movie(id)
  erb :'movies/show'
end

get '/filter/' do
  redirect '/movies'
end

get '/movies/:id' do
  id = params[:id]
  @movie = find_movie_by_id(id)
  @letters = 'a'.upto('z').to_a
  @actors = find_actors_by_movie(id)
  erb :'movies/show'
end

get '/' do
  redirect '/movies'
end
