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
  hand_total=cards.values.inject{|a,b|a+b}
  ace_count=cards.select{|k,v|v==11}.count
  
  while ace_count !=0 && hand_total>21 do
    hand_total-=10
    ace_count-=1
  end  
  hand_total
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

def gameover(status)
  @hit_or_stay=false
  @dealer_turn=false
  @game_done=true

  if status=="p_win"
    session["bank"]+=session["bet"].to_i
  elsif status=="d_win"
    session["bank"]-=session["bet"].to_i
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


get '/' do 
  session["bank"]=500
  erb :home
end

get '/game' do
  erb :game
end


get '/show_cards' do
@flop=true
@gameover=false

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
  @flop=false
  gameover("tie")
  @success="Both players got blackjack!"
  erb :show_cards
elsif hand_total(session["player1_cards"])==21
  session["game_status"]="player_wins"
  gameover("p_win")
  @success="#{session[:player_name]} got Blackjack!"
  erb :show_cards
elsif hand_total(session["dealer_cards"])==21
  session["game_status"]="dealer_wins"
  @flop=false
  gameover("d_win")
  @error="The Dealer got blackjack.  #{session[:player_name]} lost."
  erb :show_cards
end

erb :show_cards
end


get '/players_turn' do
  @flop=true
  if bust_check(hand_total(session["player1_cards"]))==true
    gameover("d_win")
    @error="#{session[:player_name]} busted.  The Dealer wins!"
    erb :show_cards
  else
    erb :show_cards
  end
end

get '/player_stays' do
  @hit_or_stay=false
  @dealer_turn=true
  @flop=false
  erb :show_cards
end

get '/dealers_turn' do
  @hit_or_stay=false
  @dealer_turn=true
  @flop=false
  
if hand_total(session["dealer_cards"]) >=17
    if hand_total(session["dealer_cards"]) > hand_total(session["player1_cards"])
      gameover("d_win")
      @error="#{session[:player_name]} lost!  The Dealer's cards are higher"
      erb :show_cards
    else
      gameover("p_win")
      @success="#{session[:player_name]} wins!  Your cards are higher and the Dealer is above 17."
      erb :show_cards
    end
  else
    draw_card(session["deck"],session["dealer_cards"])
    if bust_check(hand_total(session["dealer_cards"]))==true
      gameover("p_win")
      @success="The Dealer busted and #{session[:player_name]} wins!"
      erb :show_cards
    else
      erb :show_cards
    end
  end
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
  if session[:bank]<=0
    @error="You're broke. Go get a job."
    halt erb :game
  elsif params[:bet].empty?
    @error="A bet is required"
    halt erb :game
  elsif session[:bank]<=0

  end
  session[:bet]=params[:bet]
  redirect '/show_cards'
end

post '/hit_me' do
  draw_card(session["deck"],session["player1_cards"])
  redirect '/players_turn'
end

post '/stay' do
  redirect '/player_stays'
end

post '/dealer_hits' do
  redirect '/dealers_turn'
end


