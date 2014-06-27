require 'rubygems'
require 'sinatra'
require 'pry'

set :sessions, true

#================================HELPERS====================================================

helpers do

def draw_card(deck_passed_in,player_cards)
  card=deck_passed_in.keys.sample #draws random card
  player_cards[card]=deck_passed_in.delete(card) #moves card from deck hash to player hash
end

def hand_total(cards)
  #if one ace exists
  if cards.select{|k,v|v==11}.count==1 && cards.select{|k,v|v!=11}.values.inject{|a,b|a+b}+11>21
  hand_total=cards.select{|k,v|v!=11}.values.inject{|a,b|a+b}+1
  #if two aces exist
  elsif cards.select{|k,v|v==11}.count==2 && cards.select{|k,v|v!=11}.values.inject{|a,b|a+b}+12>21
  hand_total=cards.select{|k,v|v!=11}.values.inject{|a,b|a+b}+2
  #if three aces exist
  elsif cards.select{|k,v|v==11}.count==3 && cards.select{|k,v|v!=11}.values.inject{|a,b|a+b}+13>21
  hand_total=cards.select{|k,v|v!=11}.values.inject{|a,b|a+b}+3
  #if four aces exist
  elsif cards.select{|k,v|v==11}.count==4 && cards.select{|k,v|v!=11}.values.inject{|a,b|a+b}+14>21
  hand_total=cards.select{|k,v|v!=11}.values.inject{|a,b|a+b}+4
  #if no aces exist
  else
  hand_total=cards.values.inject{|a,b|a+b}
  end
end

def blackjack_check(cards)
  blackjack=21
  hand_total=cards.values.inject{|a,b|a+b}
  if hand_total==blackjack
    return true
  else
    return false
  end
end

def bust_check(total)
  if total>21
    true
  else
    false
  end
end

def gameover_message(status)
  if status=="tie"
    "It's a tie!"
  elsif status=="player_wins"
    session["bank"]+=session["bet"].to_i
    " #{session[:player_name]}"+" wins!"
  elsif status=="dealer_wins"
    session["bank"]-=session["bet"].to_i
    "Dealer wins and you lose!"
  end
end


#================================IMAGE MAPPING METHODS===========================================
#This function maps 
def mapper(character)
  case 
  when character=="J" then "jack"
  when character=="Q" then "queen"
  when character=="K" then "king"
  when character=="A" then "ace"
  else character
  end

end

#This function should take a cards array in the format ["H10"=>10,"HJ"=>10]
#and convert it into an array of the names of the images
def image_names(arr)
arr.map{|x|case when x[0]=="H" then "hearts_"+mapper(x[1..2])+".jpg"
when x[0]=="S" then "spades_"+mapper(x[1..2])+".jpg"
when x[0]=="C" then "clubs_"+mapper(x[1..2])+".jpg"
when x[0]=="D" then "diamonds_"+mapper(x[1..2])+".jpg"
end}
end

#This function should output the paths to the images
#the question is how can i get this function to return
#the img src tags for all the elements in the array.
def show_images(names_of_images_array)
names_of_images_array.each do |x| puts "<img src=/images/cards/"+x+"/>"

end
# names_of_images_array.each do |x| "hello" end
  # "<img src=/images/cards/"+x+"/>"
# end
end
  

end

#================================GET ACTIONS====================================================

get '/tester' do 
  erb :tester
end

get '/' do 
  session["bank"]=500
  erb :home
end

get '/game' do
  erb :game
end

get '/show_cards' do
session["deck"]=[]
session["deck"]={"H2"=>2,"H3"=>3,"H4"=>4,"H5"=>5,"H6"=>6,"H7"=>7,"H8"=>8,"H9"=>9,"H10"=>10,"HJ"=>10,"HQ"=>10,"HK"=>10,"HA"=>11,
"C2"=>2,"C3"=>3,"C4"=>4,"C5"=>5,"C6"=>6,"C7"=>7,"C8"=>8,"C9"=>9,"C10"=>10,"CJ"=>10,"CQ"=>10,"CK"=>10,"CA"=>11,
"S2"=>2,"S3"=>3,"S4"=>4,"S5"=>5,"S6"=>6,"S7"=>7,"S8"=>8,"S9"=>9,"S10"=>10,"SJ"=>10,"SQ"=>10,"SK"=>10,"SA"=>11,
"D2"=>2,"D3"=>3,"D4"=>4,"D5"=>5,"D6"=>6,"D7"=>7,"D8"=>8,"D9"=>9,"D10"=>10,"DJ"=>10,"DQ"=>10,"DK"=>10,"DA"=>11}
session["player1_cards"]={}
session["dealer_cards"]={}


2.times {draw_card(session["deck"],session["dealer_cards"])}
2.times {draw_card(session["deck"],session["player1_cards"])}



if hand_total(session["dealer_cards"])==21 && hand_total(session["player1_cards"])==21
  session["game_status"]="tie"
  erb :gameover
elsif hand_total(session["player1_cards"])==21
  session["game_status"]="player_wins"
  erb :gameover
elsif hand_total(session["dealer_cards"])==21
  session["game_status"]="dealer_wins"
  erb :gameover
else
erb :show_cards
end
end


get '/players_turn' do
  if bust_check(hand_total(session["player1_cards"]))==true
    session["game_status"]="dealer_wins"
    erb :gameover
  else
    erb :players_turn_template
  end
end

get '/dealers_turn' do
  erb :dealers_turn_template
end

get '/gameover' do
  @error="GAMEOVER"
  erb :gameover
end


#================================POST ACTIONS====================================================
post '/set_name' do
  if params[:player_name].empty?
    @error="You must enter a name"
    halt erb :home
  end

  session[:player_name]=params[:player_name]
  redirect '/game'
end

post '/set_bet' do
  if params[:bet].empty?
    @error="A bet is required"
    halt erb :game
  end
  session[:bet]=params[:bet]
  redirect '/show_cards'
end

post '/hit_me' do
  draw_card(session["deck"],session["player1_cards"])
  redirect '/players_turn'
end

post '/stay' do
  redirect '/dealers_turn'
end

post '/dealer_hits' do
  if hand_total(session["dealer_cards"]) >=17
    if hand_total(session["dealer_cards"]) > hand_total(session["player1_cards"])
      session["game_status"]="dealer_wins"
      redirect '/gameover'
    else
      session["game_status"]="player_wins"
      redirect '/gameover'
    end
  else
    draw_card(session["deck"],session["dealer_cards"])
    if bust_check(hand_total(session["dealer_cards"]))==true
      session["game_status"]="player_wins"
      redirect '/gameover'
    else
      redirect '/dealers_turn'
    end
  end

end


