pico-8 cartridge // http://www.pico-8.com
version 18
__lua__
-- globals
game_started = false
all_suits = {'spades', 'hearts', 'diamonds', 'clubs'}
all_ranks = {'ace', 'king', 'queen', 'jack', '10', '9', '8', '7', '6', '5', '4', '3', '2'}
all_phases = {blinds='blinds', deal='deal', play='play', dealer_play='dealer_play', settlement='settlement'}

function new_deck()
  local ndeck = {}

  for i=1,#all_suits do
    for j=1,#all_ranks do
      add(ndeck, {rank=all_ranks[j], suit=all_suits[i]})
    end
  end

  return ndeck
end

deck = new_deck()
pile = {}
p_hand = {}
d_hand = {}
phase = all_phases['blinds']
max_bet = 500
min_bet = 2
balance = 450
wager = 50

-- utils
function hcenter(s)
  return 64-#s*2
end

function vcenter()
  return 61
end

function wait(a) for i = 1,a do flip() end end
-- update
function draw_card()
  if #deck == 0 then
    deck = pile
    pile = {}
  end

  local drawn_card = deck[flr(rnd(#deck) + 1)]
  del(deck, drawn_card)
  add(pile, drawn_card)

  return drawn_card
end

function update_blinds_phase()
  if btnp(5) then
    phase = all_phases['deal']
    return
  end

  local amt = 1

  if btnp(0) or btnp(1) then
    if btnp(0) then
      amt = 10
      while wager - amt < min_bet do
        amt -= 1
      end
    elseif btnp(1) and balance < 10 then
      amt = balance
    elseif btnp(1) then
      amt = 10
      while wager + amt > max_bet do
        amt -= 1
      end
    else
      amt = 10
    end
  end

  if (btnp(1) or btnp(2)) and balance > 0 and wager < max_bet then
    wager += amt
    balance -= amt
  elseif (btnp(0) or btnp(3)) and wager > min_bet then
    wager -= amt
    balance += amt
  elseif btnp(4) then
    amt = min(max_bet, balance)
    wager += amt
    balance -= amt
  end
end

function update_deal_phase()
  add(p_hand, draw_card())
  add(d_hand, draw_card())
  add(p_hand, draw_card())
  add(d_hand, draw_card())

  phase = all_phases['play']
end

function update_phase()
  if phase == all_phases['blinds'] then update_blinds_phase() end
  if phase == all_phases['deal'] then update_deal_phase() end
end

function _update()
  if btnp(5) and not game_started then
    game_started = true
  else
    update_phase()
  end
end

-- draw
function init_screen()
  local msg_1 = "blackjack"
  local msg_2 = "press x to play"
  print(msg_1, hcenter(msg_1), 54, 14)
  print(msg_2, hcenter(msg_2), 64, 7)
end

function render_blinds_phase()
  local msg_q = 'place your bet:'
  print(msg_q, hcenter(msg_q), 54, 7)
  local msg_amt = '$'..wager
  print(msg_amt, hcenter(msg_amt), 64, 3)
  local msg_bal = 'balance: $'..balance
  print(msg_bal, hcenter(msg_bal), 10, 10)
  print('⬆️ +1  ➡️ +10', 10, 110, 10)
  print('⬇️ -1  ⬅️ -10', 10, 120, 10)
  print('🅾️ max bet', 80, 110, 10)
  print('❎ confirm', 80, 120, 10)
end

function render_play_phase()
  local p_cards = p_hand[1].rank..' '..p_hand[1].suit..', '..p_hand[2].rank..' '..p_hand[2].suit
  print(p_cards, hcenter(p_cards), vcenter() + 20, 7)

  local d_cards = d_hand[1].rank..' '..d_hand[1].suit..', '..d_hand[2].rank..' '..d_hand[2].suit
  print(d_cards, hcenter(d_cards), vcenter() - 20, 7)

  print('bal: $'..balance, 10, 3, 10)
  print('bet: $'..wager, 10, 10, 10)
  print('⬆️ split', 10, 110, 10)
  print('⬇️ double', 10, 120, 10)
  print('➡️ insurance', 65, 110, 10)
  print('🅾️ hit', 65, 120, 10)
  print('❎ stay', 95, 120, 10)
end

function render_phase()
  if phase == all_phases['blinds'] then render_blinds_phase() end
  if phase == all_phases['play'] then render_play_phase() end
end

function _draw()
  cls()
  rect(0,0,127,127,7)

  if (game_started) then
    render_phase()
  else
    init_screen()
  end
end

__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
