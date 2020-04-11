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
phase = all_phases['blinds']
balance = 500
wager = 2
-- end of globals

-- utils
function hcenter(s)
  return 64-#s*2
end

function vcenter()
  return 61
end
-- end of utils

function init_screen()
  local msg_1 = "blackjack"
  local msg_2 = "press x to play"
  print(msg_1, hcenter(msg_1), 54, 14)
  print(msg_2, hcenter(msg_2), 64, 7)
end

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

function render_phase()
  if phase == all_phases['blinds'] then
    local msg_q = 'place your bet:'
    print(msg_q, hcenter(msg_q), 54, 7)
    local msg_amt = '$'..wager
    print(msg_amt, hcenter(msg_amt), 64, 3)
    local msg_bal = 'balance: $'..balance
    print(msg_bal, hcenter(msg_bal), 10, 10)
    print('⬆️ +1  ➡️ +10', 10, 110, 10)
    print('⬇️ -1  ⬅️ -10', 10, 120, 10)
    print('❎ confirm', 80, 120, 10)
  end
end

function _update()
  if btnp(5) and not game_started then
    game_started = true
  elseif phase == all_phases['blinds'] then
    local amt = 1

    if btnp(0) or btnp(1) then
      if balance < 10 then
        amt = balance
      else
        amt = 10
      end
    end

    if (btnp(1) or btnp(2)) and balance > 0 and wager < 500 then
      wager += amt
      balance -= amt
    elseif (btnp(0) or btnp(3)) and wager > 2 then
      wager -= amt
      balance += amt
    end
  end
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
