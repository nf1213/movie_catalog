require 'sinatra'
require 'sinatra/reloader'
require 'pg'

def db(sql, params = [])
  begin
    connection = PG.connect(dbname: 'movies')

    result = connection.exec_params(sql, params)
    result.to_a
  ensure
    connection.close
  end
end

def find_random_movie
  %{
  SELECT movies.id, movies.title, movies.year, movies.synopsis,
  movies.rating, genres.name AS genre, studios.name AS studio FROM movies
  JOIN genres ON genres.id = movies.genre_id
  JOIN studios ON movies.studio_id = studios.id
  ORDER BY RANDOM() LIMIT 1
}
end

def find_movie_by_id
  %{
  SELECT movies.title, movies.year, movies.synopsis,
  movies.rating, genres.name AS genre, studios.name AS studio FROM movies
  JOIN genres ON genres.id = movies.genre_id
  JOIN studios ON movies.studio_id = studios.id
  WHERE movies.id = $1 ORDER BY movies.title
}
end

def find_actor_by_id
  %{
  SELECT movies.title, cast_members.character, movies.id FROM actors
  JOIN cast_members ON cast_members.actor_id = actors.id
  JOIN movies ON cast_members.movie_id = movies.id
  WHERE actors.id = $1 ORDER BY movies.title
}
end

def find_actor_name_by_id
  %{
  SELECT name FROM actors
  WHERE id = $1
}
end

def find_movies_by_title(string)
  %{
  SELECT movies.title, movies.year, movies.rating,
  genres.name AS genre, studios.name AS studio, movies.id FROM movies
  JOIN genres ON movies.genre_id = genres.id
  JOIN studios ON movies.studio_id = studios.id
  WHERE title ILIKE '%#{string}%'
  ORDER BY title
}
end

def find_actors_by_name(string)
  %{
  SELECT name, id FROM actors
  WHERE name ILIKE '%#{string}%' ORDER BY name
}
end

def find_movies_starting_with(let)
  %{
  SELECT movies.title, movies.year, movies.rating,
  genres.name AS genre, studios.name AS studio, movies.id FROM movies
  JOIN genres ON movies.genre_id = genres.id
  JOIN studios ON movies.studio_id = studios.id
  WHERE title ILIKE '#{let}%'
  ORDER BY title
}
end

def find_actors_starting_with(let)
  %{
  SELECT name, id FROM actors
  WHERE name ILIKE '#{let}%' ORDER BY name
}
end

def find_movies
  %{
  SELECT movies.title, movies.year, movies.rating,
  genres.name AS genre, studios.name AS studio, movies.id FROM movies
  JOIN genres ON movies.genre_id = genres.id
  JOIN studios ON movies.studio_id = studios.id
  ORDER BY title
}
end

def find_actors
  %{
  SELECT name, id FROM actors ORDER BY name
}
end

def find_actors_by_movie_id
  %{
  SELECT actors.name, cast_members.character, actors.id FROM cast_members
  JOIN movies ON cast_members.movie_id = movies.id
  JOIN actors ON cast_members.actor_id = actors.id
  WHERE movies.id = $1
  ORDER BY title
}
end

get '/movies' do
  @movies = db(find_movies)
  @letters = 'a'.upto('z').to_a

  filter = params[:filter]

  if filter
    filter.gsub!("+", " ")

    if filter.length == 1
      @movies = db(find_movies_starting_with(filter))
    else
      @movies = db(find_movies_by_title(filter))
    end
    @movies = db(find_movies_by_title(filter))
  end
  erb :'movies/index'
end

get '/actors' do
  @actors = db(find_actors)
  @letters = 'a'.upto('z').to_a
  filter = params[:filter]

  if filter
    filter.gsub!("+", " ")

    if filter.length == 1
      @actors = db(find_actors_starting_with(filter))
    else
      @actors = db(find_actors_by_name(filter))
    end
  end
  erb :'actors/index'
end

get '/actors/:id' do
  @letters = 'a'.upto('z').to_a
  id = params[:id]
  @actor = db(find_actor_by_id, [id])
  @name = db(find_actor_name_by_id, [id])[0]['name']
  erb :'actors/show'
end

get '/search/' do
  search = params[:filter]
  search.gsub!(" ", "+")

  if params[:select] == "movies"
    redirect "/movies?filter=#{search}"
  else
    redirect "/actors?filter=#{search}"
  end
end

get '/random' do
  @letters = @letters = 'a'.upto('z').to_a
  @movie = db(find_random_movie).first
  id = @movie['id']
  @actors = db(find_actors_by_movie_id, [id])
  erb :'movies/show'
end

get '/movies/:id' do
  id = params[:id]
  @movie = db(find_movie_by_id, [id]).first
  @letters = 'a'.upto('z').to_a
  @actors = db(find_actors_by_movie_id, [id])
  erb :'movies/show'
end

get '/' do
  redirect '/movies'
end
