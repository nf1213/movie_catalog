require 'sinatra'
require 'sinatra/reloader'
require 'csv'

def random_number
 random = 0
  while !@movies.has_key?(random.to_s) do
    random = rand(@movies.size).round
    rand
  end
  random
end

def movies_from_csv
  movies = []

  CSV.foreach('movies.csv', headers: true) do |row|
      movies << {
        id: row['id'],
        title: row['title'],
        year: row['year'],
        synopsis: row['synopsis'],
        rating: row['rating'],
        genre: row['genre'],
        studio: row['studio']
      }
  end

  movies
end

def movie_hash
  movies_array = movies_from_csv

  movies_array.sort_by! { |movie| movie[:title]}

  hash = {}

  movies_array.each do |movie|
    hash[movie[:id]] = movie
  end
  
  hash
end

get '/movies' do
  @movies = movie_hash
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
  @movies = movie_hash
  @filter = params[:filter]
  @random = random_number
  erb :index
end

get '/filter/' do
  redirect '/movies'
end

get '/movies/:id' do
  @movies = movie_hash
  @movie = @movies[params[:id]]
  @letters = 'a'.upto('z').to_a
  @random = random_number
  erb :show
end

get '/' do
  redirect '/movies'
end
