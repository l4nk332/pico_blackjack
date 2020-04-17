pico-8 cartridge // http://www.pico-8.com
version 18
__lua__
-- pico blackjack
-- by l4nk332

cartdata("l4nk332_blackjack")

-- globals
game_started = false
all_suits = {'spades', 'hearts', 'diamonds', 'clubs'}
suit_reg = {diamonds=1, hearts=2, spades=3, clubs=4}
suit_color = {diamonds=8, hearts=8, spades=5, clubs=5}
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
s_hand = {}
d_hand = {}
phase = all_phases['blinds']
max_bet = 500
min_bet = 2
balance = dget(0)
if not balance or balance == 0 then
  balance = 500
end
wager = 50
insurance = 0
insurance_applies = false
is_double_down = false
is_split = false
is_surrender = false
did_win = nil

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

function can_hit()
  return value_of_hand(p_hand) < 21
end

function can_insure()
  return insurance == 0 and balance >= flr(wager / 2) and d_hand[1].rank == 'ace'
end

function can_double_down()
  return value_of_hand(p_hand) < 21 and (balance >= wager + insurance) and not is_double_down
end

function can_split()
  return (balance >= wager + insurance) and (p_hand[1].rank == p_hand[2].rank) and not is_split
end

function can_surrender()
  return not (is_split or insurance > 0 or #p_hand > 2 or value_of_hand(p_hand) == 21)
end


-- update
function reset_play()
  p_hand = {}
  d_hand = {}
  s_hand = {}
  phase = all_phases['blinds']
  insurance = 0
  is_double_down = false
  is_split = false
  is_surrender = false
  dset(0, balance)
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
  end
end

function update_deal_phase()
  add(p_hand, draw_card())
  add(d_hand, draw_card())
  add(p_hand, draw_card())
  add(d_hand, draw_card())

  phase = all_phases['play']
end

function double_wager()
  balance -= wager
  wager *= 2
  if insurance > 0 then insurance = flr(wager / 2) end
end

function add_insurance()
  local amt = flr(wager / 2)
  insurance = amt
  balance -= amt
end

function is_split_remaining()
  return is_split and #s_hand == 1
end

function swap_split()
  local temp = s_hand
  s_hand = p_hand
  p_hand = temp
end

function update_play_phase()
  if btnp(5) and can_hit() then
    add(p_hand, draw_card())
    if value_of_hand(p_hand) > 21 then
      if is_split then
        if is_split_remaining() then
          swap_split()
          add(p_hand, draw_card())
        elseif value_of_hand(p_hand) <= 21 or value_of_hand(s_hand) <= 21 then
          phase = all_phases['dealer_play']
        end
      else
        phase = all_phases['settlement']
      end
    end
  elseif btnp(3) and can_double_down() then
    is_double_down = true
    double_wager()
    add(p_hand, draw_card())
    if value_of_hand(p_hand) > 21 then
      phase = all_phases['settlement']
    else
      phase = all_phases['dealer_play']
    end
  elseif btnp(0) and can_insure() then
    add_insurance()
  elseif btnp(1) and can_surrender() then
    is_surrender = true
  elseif btnp(2) and can_split() then
    is_split = true
    s_hand = {p_hand[2]}
    p_hand = {p_hand[1]}
    add(p_hand, draw_card())
    double_wager()
  elseif btnp(4) then
    if is_split_remaining() then
      swap_split()
      add(p_hand, draw_card())
    else
      phase = all_phases['dealer_play']
    end
  end
end

function update_surrender()
  if btnp(4) then
    is_surrender = false
  elseif btnp(5) then
    balance -= ceil(wager / 2)
    reset_play()
  end
end


function update_settlement_phase()
  local wager_amt = wager
  local insurance_amt = insurance
  if is_split then
    wager_amt = wager_amt / 2
    insurance_amt = insurance_amt / 2
  end

  if btnp(5) then
    if did_win == true then
      balance += (wager_amt * 2) - insurance_amt
    elseif did_win == false then
      if insurance_applies and insurance > 0 then
        balance += insurance_amt * 2
      else
        local next_wager = wager_amt
        if is_double_down then
          next_wager = flr(wager_amt / 2)
        end
        next_wager = min(min(next_wager, max_bet), balance)

        -- we do this to set up for next blinds
        if not is_split or #s_hand == 0 then wager = next_wager end
        balance -= next_wager
      end
    else
      balance += wager_amt + insurance_amt
    end

    if is_split and #s_hand > 0 then
      swap_split()
      s_hand = {}
    else
      reset_play()
    end
  end
end

function reset_balance()
  balance = 500
  wager = 50
  reset_play()
end

function update_game_over()
  if btnp(5) then
    reset_balance()
  end
end

function update_phase()
  if (balance <= 0 and wager <= 0) or balance < -10000 then
    update_game_over()
  elseif phase == all_phases['blinds'] then
    update_blinds_phase()
  elseif phase == all_phases['deal'] then
    update_deal_phase()
  elseif phase == all_phases['play'] then
    update_play_phase()
  elseif phase == all_phases['settlement'] then
    update_settlement_phase()
  end
end

function _update()
  if btnp(5) and not game_started then
    game_started = true
  elseif is_surrender then
    update_surrender()
  else
    update_phase()
  end
end

-- draw
function init_screen()
  local msg_1a = 'pico'
  local msg_1b = "blackjack"
  local msg_2 = "press x to play"
  print(msg_1a, (hcenter(msg_1a) - #msg_1b*2) - 1, 54, 14)
  print(msg_1b, (hcenter(msg_1b) + #msg_1a*2) + 1, 54, 5)
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
  print('❎ confirm', 80, 120, 10)
end

function render_card(card, x, y, is_face_down)
  local reg = suit_reg[card.suit]
  local clr = suit_color[card.suit]
  local sym = card.rank
  if #sym > 2 then sym = sub(sym, 1, 1) end

  if is_face_down then
    rectfill(x, y, x + 20, y + 25, 8)
    rect(x + 2, y + 2, x + 18, y + 23, 7)
  else
    rectfill(x, y, x + 20, y + 25, 7)
    local sym_offset
    if #sym == 2 then sym_offset = 2 else sym_offset = 6 end
    print(sym, x + 2, y + 2, clr)
    print(sym, x + 10 + sym_offset, y + 19, clr)
    spr(reg, ((x * 2 + 20) / 2) - 3, ((y * 2 + 25) / 2) - 3)
  end
end

function render_s_hand(vshift)
  vshift = vshift or 0
  for i=1,#s_hand do
    render_card(s_hand[i], 63 + (i * 10), vcenter() + 15 + vshift)
  end

  local hand_value = tostr(value_of_hand(s_hand))..' - hand 1'
  print(hand_value, 74, vcenter() + 7 + vshift, 7)
end

function render_p_hand(vshift, hand_number)
  vshift = vshift or 0
  for i=1,#p_hand do
    render_card(p_hand[i], i * 10, vcenter() + 15 + vshift)
  end

  local hand_value = tostr(value_of_hand(p_hand))
  if is_split then
    if hand_number then
      hand_value = hand_value..' - hand '..hand_number
    elseif is_split_remaining() then
      hand_value = hand_value..' - hand 1'
    else
      hand_value = hand_value..' - hand 2'
    end
  end
  print(hand_value, 10, vcenter() + 7 + vshift, 7)
end

function render_d_hand(is_face_down, vshift)
  vshift = vshift or 0
  for i=1,#d_hand do
    if is_face_down and i == 2 then
      render_card(d_hand[i], i * 10, vcenter() - 30 + vshift, is_face_down)
    else
      render_card(d_hand[i], i * 10, vcenter() - 30 + vshift)
    end
  end
  if not is_face_down then
    local hand_value = tostr(value_of_hand(d_hand))
    print(hand_value, 10, vcenter() - 1 + vshift, 7)
  end
end

function render_funds()
  print('bal: $'..balance, 10, 3, 10)
  print('bet: $'..wager, 10, 10, 10)
  print('ins: $'..insurance, 10, 17, 10)
end

function render_play_phase()
  render_p_hand()
  if is_split and #s_hand > 1 then render_s_hand() end
  render_d_hand(true)

  local opt_ctl_clr = 10
  if #p_hand > 2 then opt_ctl_clr = 5 end

  local split_clr = opt_ctl_clr
  if is_split then
    split_clr = 6
  elseif not can_split() then
    split_clr = 5
  end

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

  local srndr_clr = opt_ctl_clr
  if not can_surrender() then
    srndr_clr = 5
  end

  local hit_clr = 10
  if not can_hit() then hit_clr = 5 end

  render_funds()
  print('⬆️ split', 10, 110, split_clr)
  print('⬇️ double', 10, 120, double_clr)
  print('⬅️ ins', 65, 110, insurance_clr)
  print('➡️ srnd', 95, 110, srndr_clr)
  print('❎ hit', 65, 120, hit_clr)
  print('🅾️ stay', 95, 120, 10)
end


function render_dealer_play_phase()
  render_funds()
  render_p_hand()
  if is_split then render_s_hand() end
  render_d_hand()

  if value_of_hand(d_hand) < 17 then
    add(d_hand, draw_card())
  else
    phase = all_phases['settlement']
  end

  wait(2)
end

function render_settlement_phase()
  local p_hand_val = value_of_hand(p_hand)
  local d_hand_val = value_of_hand(d_hand)
  local result_phrase = ''
  local reveal_dealer = true

  if p_hand_val > 21 then
    result_phrase = 'you busted'
    did_win = false
    if #d_hand < 3 then reveal_dealer = false end
  elseif d_hand_val > 21 then
    result_phrase = 'house busted'
    did_win = true
  elseif d_hand_val < p_hand_val and p_hand_val <= 21 then
    if p_hand_val == 21 and #p_hand == 2 then
      result_phrase = "you're a natural"
    elseif p_hand_val == 21 and #p_hand > 2 then
      result_phrase = "quite a soft touch"
    else
      result_phrase = 'you topped the house'
    end
    did_win = true
  elseif d_hand_val > p_hand_val and d_hand_val <= 21 then
    if d_hand_val == 21 then
      result_phrase = "house wins with blackjack"
      if #d_hand == 2 then
        insurance_applies = true
      end
    else
      result_phrase = 'house topped you'
    end
    did_win = false
  elseif d_hand_val == p_hand_val then
    if p_hand_val == 21 then
      if #p_hand == 2 and #d_hand > 2 then
        result_phrase = "your natural beats soft 21"
        did_win = true
      elseif #d_hand == 2 and #p_hand > 2 then
        result_phrase = "house natural beats soft 21"
        did_win = false
        insurance_applies = true
      else
        result_phrase = "it's a push"
        did_win = nil
      end
    else
      result_phrase = "it's a push"
      did_win = nil
    end
  else
    print('settlement', hcenter('settlement'), vcenter('settlement'), 7)
  end

  local result_clr, amt_str
  local wager_amt = wager
  local insurance_amt = insurance

  if is_split then
    wager_amt = wager / 2
    insurance_amt = insurance / 2
  end

  if did_win == nil then
    result_clr = 7
    amt_str = '$0'
  elseif did_win then
    result_clr = 3
    amt_str = '+$'..tostr((wager_amt * 2) - insurance_amt)
  else
    result_clr = 8
    amt_str = '-$'..tostr(wager_amt + insurance_amt)
  end

  if did_win == false and insurance_applies and insurance > 0 then
    result_clr = 7
    amt_str = "$0 - insured"
  end

  render_d_hand(not reveal_dealer, -20)
  print(result_phrase, hcenter(result_phrase), vcenter() - 5, 7)
  print(amt_str, hcenter(amt_str), vcenter() + 5, result_clr)

  local hand_number
  if is_split then
    if #s_hand > 0 then hand_number = '1' else hand_number = '2' end
  end

  render_p_hand(15, hand_number)

  local adv_msg
  if #s_hand > 0 then
    adv_msg = 'next hand'
  else
    adv_msg = 'play again'
  end
  print('❎ '..adv_msg, 70, 120, 10)
end

function render_game_over()
  local s = 'you broke the bank!'
  print(s, hcenter(s), vcenter(), 8)

  print('❎ reset balance', 60, 120, 10)
end

function render_you_win()
  local s1 = 'you rake in the last of the'
  local s2 = 'chips, tip your hat, and'
  local s3 = 'ride off into the distance.'
  local s4 = 'you arrived nameless and'
  local s5 = 'unknown but you left a'
  local s6 = 'folktale legend...'
  local s7 = 'blackjack'
  print(s1, hcenter(s1), 10, 7)
  print(s2, hcenter(s2), 25, 7)
  print(s3, hcenter(s3), 40, 7)
  print(s4, hcenter(s4), 55, 7)
  print(s5, hcenter(s5), 70, 7)
  print(s6, hcenter(s6), 85, 7)
  print(s7, hcenter(s7), 100, 5)
  print('❎ restart game', 60, 120, 10)
end

function render_phase()
  if balance < -10000 then render_you_win()
  elseif balance <= 0 and wager <= 0 then render_game_over()
  elseif phase == all_phases['blinds'] then render_blinds_phase()
  elseif phase == all_phases['play'] then render_play_phase()
  elseif phase == all_phases['dealer_play'] then render_dealer_play_phase()
  elseif phase == all_phases['settlement'] then render_settlement_phase() end
end

function render_surrender()
  local title = 'surrender?'
  local text = 'you will lose half your wager'
  local wager_amt = '-$'..tostr(ceil(wager / 2))

  print(title, hcenter(title), vcenter() - 15, 7)
  print(text, hcenter(text), vcenter() - 5, 7)
  print(wager_amt, hcenter(wager_amt), vcenter() + 5, 8)
  print('❎ yes', 65, 120, 10)
  print('🅾️ no', 95, 120, 10)
end

function _draw()
  cls()
  rect(0,0,127,127,7)

  if (game_started) then
    if is_surrender then
      render_surrender()
    else
      render_phase()
    end
  else
    init_screen()
  end
end

menuitem(2, 'reset balance', reset_balance)

__gfx__
00000000000880000880088000055000055555500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000008888008888888800555500005555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700088888808888888805555550500550050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000888888888888888805555550555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000888888880888888055555555550550550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700088888800088880055055055500550050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000008888000008800000055000000550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000880000000000000055000000550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
