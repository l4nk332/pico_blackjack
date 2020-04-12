pico-8 cartridge // http://www.pico-8.com
version 18
__lua__
-- globals
game_started = false
all_suits = {'spades', 'hearts', 'diamonds', 'clubs'}
all_ranks = {'ace', 'king', 'queen', 'jack', '10', '9', '8', '7', '6', '5', '4', '3', '2'}
all_values = {{1, 11}, 10, 10, 10, 10, 9, 8, 7, 6, 5, 4, 3, 2}
all_phases = {blinds='blinds', deal='deal', play='play', dealer_play='dealer_play', settlement='settlement'}

function new_deck()
  local ndeck = {}

  for i=1,#all_suits do
    for j=1,#all_ranks do
      add(ndeck, {rank=all_ranks[j], suit=all_suits[i], value=all_values[j]})
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
insurance = 0
is_double_down = false

-- utils
function hcenter(s)
  return 64-#s*2
end

function vcenter()
  return 61
end

function wait(s) for i = 1,s*30 do flip() end end

function value_of_hand(hand)
  local value = 0
  local ace_count = 0
  for i=1,#hand do
    if hand[i].rank == 'ace' then
      ace_count += 1
      value += 1
    else
      value += hand[i].value
    end
  end

  if ace_count > 0 and value < 21 then
    -- because ace is already accounted for as 1 we do (value - 1) + 11
    -- which ends up just being +10
    if value + 10 <= 21 then
      value += 10
    end
  end

  return value
end

function can_insure()
  return insurance == 0 and balance >= flr(wager / 2)
end

function can_double_down()
  return (balance >= wager + insurance) and not is_double_down
end

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

function update_play_phase()
  if btnp(4) then
    add(p_hand, draw_card())
    if value_of_hand(p_hand) > 21 then
      phase = all_phases['settlement']
    end
  elseif btnp(3) and can_double_down() then
    is_double_down = true
    balance -= wager
    wager *= 2
    if insurance > 0 then insurance = flr(wager / 2) end
  elseif btnp(1) and can_insure() then
    local amt = flr(wager / 2)
    insurance = amt
    balance -= amt
  elseif btnp(5) then
    phase = all_phases['dealer_play']
  end
end

function update_phase()
  if phase == all_phases['blinds'] then
    update_blinds_phase()
  elseif phase == all_phases['deal'] then
    update_deal_phase()
  elseif phase == all_phases['play'] then
    update_play_phase()
  end
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

function render_p_hand()
  local hand_str = ''
  for i=1,#p_hand do
    local t = ', '
    if i == #p_hand then t = '' end
    hand_str = hand_str..p_hand[i].rank..' '..sub(p_hand[i].suit, 1, 1)..t
  end
  print(hand_str, hcenter(hand_str), vcenter() + 20, 7)
  local hand_value = tostr(value_of_hand(p_hand))
  print(hand_value, hcenter(hand_value), vcenter() + 30, 7)
end

function render_d_hand(is_face_down)
  local hand_str = ''
  for i=1,#d_hand do
    local t = ', '
    if i == #d_hand then t = '' end
    if is_face_down and i == 2 then
      hand_str = hand_str..'???'
    else
      hand_str = hand_str..d_hand[i].rank..' '..sub(d_hand[i].suit, 1, 1)..t
    end

  end
  print(hand_str, hcenter(hand_str), vcenter() - 30, 7)
  if not is_face_down then
    local hand_value = tostr(value_of_hand(d_hand))
    print(hand_value, hcenter(hand_value), vcenter() - 20, 7)
  end
end

function render_funds()
  print('bal: $'..balance, 10, 3, 10)
  print('bet: $'..wager, 10, 10, 10)
  print('ins: $'..insurance, 10, 17, 10)
end

function render_play_phase()
  render_p_hand()
  render_d_hand(true)

  local opt_ctl_clr = 10
  if #p_hand > 2 then opt_ctl_clr = 5 end

  local split_clr = opt_ctl_clr
  if p_hand[1].rank != p_hand[2].rank then split_clr = 5 end

  local double_clr = opt_ctl_clr
  if is_double_down then
    double_clr = 6
  elseif not can_double_down() then
    double_clr = 5
  end

  local insurance_clr = opt_ctl_clr
  if insurance > 0 then
    insurance_clr = 6
  elseif not can_insure() then
    insurance_clr = 5
  end

  render_funds()
  print('⬆️ split', 10, 110, split_clr)
  print('⬇️ double', 10, 120, double_clr)
  print('➡️ insurance', 65, 110, insurance_clr)
  print('🅾️ hit', 65, 120, 10)
  print('❎ stay', 95, 120, 10)
end


function render_dealer_play_phase()
  render_funds()
  render_p_hand()
  render_d_hand()

  if value_of_hand(d_hand) < 17 then
    add(d_hand, draw_card())
  else
    phase = all_phases['settlement']
  end

  wait(2)
end

function render_settlement_phase()
  local amt_lost = '-$'..tostr(wager + insurance)
  local amt_won = '+$'..tostr(wager)
  if value_of_hand(p_hand) > 21 then
    local bst_str = 'you busted'
    print(bst_str, hcenter(bst_str), vcenter() - 30, 7)
    print(amt_lost, hcenter(amt_lost), vcenter() - 20, 8)
    render_p_hand()
  elseif value_of_hand(d_hand) > 21 then
    local bst_str = 'dealer busted'
    print(bst_str, hcenter(bst_str), vcenter() - 30, 7)
    print(amt_won, hcenter(amt_won), vcenter() - 20, 3)
    render_p_hand()
  else
    print('settlement', hcenter('settlement'), vcenter('settlement'), 7)
  end
end

function render_phase()
  if phase == all_phases['blinds'] then render_blinds_phase() end
  if phase == all_phases['play'] then render_play_phase() end
  if phase == all_phases['dealer_play'] then render_dealer_play_phase() end
  if phase == all_phases['settlement'] then render_settlement_phase() end
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
