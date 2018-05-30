# compare with answer at 'https://launchschool.com/exercises/a1938086'
# note : the Deck and Card classes are not displayed on the above page, but the answer sections to the two previous exercise problems
# after I get my application to work as intended, I should compare my solution to LS. typically my solution is very similar to theirs but before i submit any portfolio work to job applications I should go back through each application line by line comparing my code to the LS solution, optimizing the code where necessary, and retaining my originality where else where

class Deck 
  RANKS = (2..10).to_a + %w(Jack Queen King Ace).freeze
  SUITS = %w(Hearts Clubs Diamonds Spades).freeze

  def initialize
    @deck = []
    new_deck
  end

  def new_deck 
    RANKS.each do |rank|
      SUITS.each do |suit|
        @deck << Card.new(rank, suit)
      end
    end
    @deck.shuffle!
  end

  def draw
    card = @deck.pop
    new_deck if @deck.size == 0
    card
  end
end

class Card < Deck 
  attr_reader :rank, :suit

  VALUES = { 'Jack' => 11, 'Queen' => 12, 'King' => 13, 'Ace' => 14 }
  FACE_CARD_NAME = { 11 => 'Jack', 12 => 'Queen', 13 => 'King', 14 => 'Ace' }

  def initialize(rank, suit)
    @rank = VALUES.fetch(rank, rank)
    @suit = suit
  end

  def to_s
    "#{FACE_CARD_NAME.fetch(@rank, @rank)} of #{@suit}"
  end
end

class PokerHand
  def initialize(deck) # passes in new shuffled deck
    @hand = []
    5.times do 
      @hand << deck.draw
    end
  end

  def print
    puts @hand
  end

  def evaluate
    case
    when royal_flush?     then 'Royal flush'
    when straight_flush?  then 'Straight flush'
    when four_of_a_kind?  then 'Four of a kind'
    when full_house?      then 'Full house'
    when flush?           then 'Flush'
    when straight?        then 'Straight'
    when three_of_a_kind? then 'Three of a kind'
    when two_pair?        then 'Two pair'
    when pair?            then 'Pair'
    else                       'High card'
    end
  end

  private

  def royal_flush?
    matching_suit? && straight? && hand_ranks == [10,11,12,13,14]
  end

  def straight_flush?
    matching_suit? && straight?
  end

  def four_of_a_kind? # 4 of any rank exist
    card_count.any? { |rank, count| count == 4 }
  end

  def full_house? # 2 and 3 counts of any ranks exist
    card_count.any? { |rank, count| count == 3 } && card_count.any? { |rank, count| count == 2 }
  end

  def flush?
    matching_suit?
  end

  def straight?
    if low_straight? # ace low straight
      true
    else # traditional straight
      hand_ranks.max == hand_ranks.min + 4 && hand_ranks.uniq.size == 5 
    end
  end

  def low_straight?
    hand_ranks == [2,3,4,5,14]
  end

  def three_of_a_kind?
    card_count.any? { |rank, count| count == 3 }
  end

  def two_pair?  
    card_count.select { |rank, count| count == 2 }.count == 2
  end

  def pair?
    card_count.any? { |rank, count| count == 2 }
  end

  def matching_suit?
    first_card_suit = @hand[0].suit 
    @hand.all? { |card| card.suit == first_card_suit }
  end

  def card_count # return card_count hash
    card_count = Hash.new(0)

    hand_ranks.each do |rank|
      card_count[rank] += 1
    end
    card_count 
  end

  def hand_ranks # map hand to card rank only
    @hand.map { |card| card.rank }.sort
  end
end

# END OF ASHER'S CODE: ALL TEST CASES BELOW COPIED FROM LAUNCH SCHOOL 

hand = PokerHand.new(Deck.new)
hand.print
puts hand.evaluate

# # patching for testing purposes.
class Array
  alias_method :draw, :pop
end

# Test that we can identify each PokerHand type.
hand = PokerHand.new([
  Card.new(10,      'Hearts'),
  Card.new('Ace',   'Hearts'),
  Card.new('Queen', 'Hearts'),
  Card.new('King',  'Hearts'),
  Card.new('Jack',  'Hearts')
])
puts hand.evaluate == 'Royal flush'

hand = PokerHand.new([
  Card.new(14, 'Clubs'),
  Card.new(2,  'Clubs'),
  Card.new(3, 'Clubs'),
  Card.new(4,  'Clubs'),
  Card.new(5,  'Clubs')
])
puts hand.evaluate == 'Straight flush'

hand = PokerHand.new([
  Card.new(3, 'Hearts'),
  Card.new(3, 'Clubs'),
  Card.new(5, 'Diamonds'),
  Card.new(3, 'Spades'),
  Card.new(3, 'Diamonds')
])
puts hand.evaluate == 'Four of a kind'

hand = PokerHand.new([
  Card.new(3, 'Hearts'),
  Card.new(3, 'Clubs'),
  Card.new(5, 'Diamonds'),
  Card.new(3, 'Spades'),
  Card.new(5, 'Hearts')
])
puts hand.evaluate == 'Full house'

hand = PokerHand.new([
  Card.new(10, 'Hearts'),
  Card.new('Ace', 'Hearts'),
  Card.new(2, 'Hearts'),
  Card.new('King', 'Hearts'),
  Card.new(3, 'Hearts')
])
puts hand.evaluate == 'Flush'

hand = PokerHand.new([
  Card.new(8,      'Clubs'),
  Card.new(9,      'Diamonds'),
  Card.new(10,     'Clubs'),
  Card.new(7,      'Hearts'),
  Card.new('Jack', 'Clubs')
])
puts hand.evaluate == 'Straight'

hand = PokerHand.new([
  Card.new(3, 'Hearts'),
  Card.new(3, 'Clubs'),
  Card.new(5, 'Diamonds'),
  Card.new(3, 'Spades'),
  Card.new(6, 'Diamonds')
])
puts hand.evaluate == 'Three of a kind'

hand = PokerHand.new([
  Card.new(9, 'Hearts'),
  Card.new(9, 'Clubs'),
  Card.new(5, 'Diamonds'),
  Card.new(8, 'Spades'),
  Card.new(5, 'Hearts')
])
puts hand.evaluate == 'Two pair'

hand = PokerHand.new([
  Card.new(2, 'Hearts'),
  Card.new(9, 'Clubs'),
  Card.new(5, 'Diamonds'),
  Card.new(9, 'Spades'),
  Card.new(3, 'Diamonds')
])
puts hand.evaluate == 'Pair'

hand = PokerHand.new([
  Card.new(2,      'Hearts'),
  Card.new('King', 'Clubs'),
  Card.new(5,      'Diamonds'),
  Card.new(9,      'Spades'),
  Card.new(3,      'Diamonds')
])
puts hand.evaluate == 'High card'
