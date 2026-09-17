# ============================================================
# RUBY QUICK REFERENCE
# ============================================================


# ------------------------------------------------------------
# 1. VARIABLES
# ------------------------------------------------------------

name = "John"       # String
age = 25            # Integer
price = 10.50       # Float
active = true       # Boolean
nothing = nil       # Similar concept to NULL in C

# Ruby variables do not have declared types.
# No semicolon is normally needed.


# ------------------------------------------------------------
# 2. PRINTING
# ------------------------------------------------------------

puts "Hello"                # Prints with newline
print "Hello"               # Prints without automatically adding newline

# String interpolation:
puts "My name is #{name} and I am #{age}"


# ------------------------------------------------------------
# 3. CONDITIONS
# ------------------------------------------------------------

if age >= 18
    puts "Adult"
else
    puts "Minor"
end

# Comparisons:
# ==    equal
# !=    not equal
# >     greater than
# <     less than
# >=    greater/equal
# <=    less/equal

# Logical operators:
# &&    AND
# ||    OR
# !     NOT


# ------------------------------------------------------------
# 4. METHODS
# ------------------------------------------------------------

def add(a, b)
    a + b
end

result = add(5, 3)

# Ruby automatically returns the value of the final expression.
# You can also explicitly use:
#
# return a + b


# ------------------------------------------------------------
# 5. ARRAYS
# ------------------------------------------------------------

numbers = [10, 20, 30]

puts numbers[0]     # 10
puts numbers[1]     # 20

numbers << 40       # Append 40

puts numbers.length # Number of elements


# ------------------------------------------------------------
# 6. EACH LOOP
# ------------------------------------------------------------

numbers.each do |number|
    puts number
end

# Ruby automatically moves to the next element.
# "number" represents the current element.


# ------------------------------------------------------------
# 7. EACH WITH INDEX
# ------------------------------------------------------------

names = ["John", "Alice", "Bob"]

names.each_with_index do |current_name, index|
    puts "#{index}: #{current_name}"
end

# Ruby manages the index automatically.


# ------------------------------------------------------------
# 8. WHILE LOOP
# ------------------------------------------------------------

i = 0

while i < 3
    puts i
    i += 1
end


# ------------------------------------------------------------
# 9. NESTED LOOPS
# ------------------------------------------------------------

rows = ["A", "B"]
numbers = [1, 2, 3]

rows.each do |row|

    numbers.each do |number|
        puts "#{row} #{number}"
    end

end

# Output:
# A 1
# A 2
# A 3
# B 1
# B 2
# B 3


# ------------------------------------------------------------
# 10. HASHES
# ------------------------------------------------------------

person = {
    "name" => "John",
    "age" => 25
}

puts person["name"]
puts person["age"]

# Hash = key/value pairs.
# Useful for representing one row/record of data.


# ------------------------------------------------------------
# 11. ARRAY OF HASHES
# ------------------------------------------------------------

people = [
    {"name" => "John", "age" => 25},
    {"name" => "Alice", "age" => 30},
    {"name" => "Bob", "age" => 21}
]

puts people[1]["name"]       # Alice

people.each do |person|
    puts "#{person["name"]} is #{person["age"]}"
end

# Very important pattern for database-style data:
#
# Array        = table
# Hash         = row
# Hash key     = column
# Hash value   = cell


# ------------------------------------------------------------
# 12. SYMBOLS
# ------------------------------------------------------------

direction = :asc
operation = :select
status = :waiting

# Symbols are named values/identifiers.
# They can be useful like flags, states or options.

if direction == :asc
    puts "Ascending"
end


# ------------------------------------------------------------
# 13. SYMBOLS AS HASH KEYS
# ------------------------------------------------------------

student = {
    name: "Alice",
    age: 30
}

puts student[:name]
puts student[:age]

# IMPORTANT:
# student[:name]
# and
# student["name"]
#
# are NOT the same key.


# ------------------------------------------------------------
# 14. CLASSES
# ------------------------------------------------------------

class Person

    # initialize runs when Person.new(...) is called.
    def initialize(name, age)
        @name = name
        @age = age
    end

    # Methods belonging to Person objects are defined
    # inside the class.
    def introduce
        puts "My name is #{@name} and I am #{@age}"
    end

end

john = Person.new("John", 25)
alice = Person.new("Alice", 30)

john.introduce
alice.introduce

# Person = class / blueprint
#
# john and alice = separate Person objects
#
# @name and @age = instance variables belonging
# to each individual object.


# ------------------------------------------------------------
# 15. COMMON ARRAY METHODS
# ------------------------------------------------------------

numbers = [10, 20, 30, 40]

numbers.length       # Number of elements
numbers.first        # First element
numbers.last         # Last element
numbers.include?(20) # true
numbers.empty?       # false


# ------------------------------------------------------------
# 16. NIL CHECK
# ------------------------------------------------------------

value = nil

if value.nil?
    puts "Nothing here"
end


# ------------------------------------------------------------
# 17. USEFUL STRING METHODS
# ------------------------------------------------------------

text = "Hello Ruby"

text.length
text.upcase
text.downcase
text.include?("Ruby")

# Many Ruby methods ending in ? answer a question
# and normally return true or false.


# ------------------------------------------------------------
# 18. COMMENTS
# ------------------------------------------------------------

# Single-line comment

name = "John"  # Comment after code


# ============================================================
# ALLOCINE REMINDER
# ============================================================

# For my_allocine.rb you mainly need:
#
# - Strings
# - Hash access
# - Basic Ruby syntax
#
# Example structure from the assignment:
#
# requests["description"] = "SQL QUERY"
#
# Most of the actual learning in Allocine will be SQL,
# not Ruby.
#
# Classes, arrays of hashes, loops, etc. become much more
# important in the later MySqliteRequest project.
# ============================================================

movies.db
│
├── actors
│   ├── id              Actor ID
│   ├── act_fname       First name
│   ├── act_lname       Last name
│   └── act_gender      Gender
│
├── genres
│   ├── id              Genre ID
│   └── gen_title       Genre name
│
├── directors
│   ├── id              Director ID
│   ├── dir_fname       First name
│   └── dir_lname       Last name
│
├── movies
│   ├── id              Movie ID
│   ├── mov_title       Movie title
│   ├── mov_year        Release year
│   ├── mov_time        Duration
│   ├── mov_lang        Language
│   ├── mov_dt_rel      Release date
│   └── mov_rel_country Release country
│
├── reviews
│   ├── id              Reviewer ID
│   └── rev_name        Reviewer name
│
├── movies_genres
│   ├── mov_id          → movie
│   └── gen_id          → genre
│
├── directors_movies
│   ├── dir_id          → director
│   └── mov_id          → movie
│
├── movies_actors
│   ├── act_id          → actor
│   ├── mov_id          → movie
│   └── role            Character/role played
│
└── movies_ratings_reviews
    ├── mov_id          → movie
    ├── rev_id          → reviewer
    ├── rev_stars       Stars given
    └── num_o_rating    Number of ratings

    .tables  #shows what exists 

    2661,618
    1796

    2115.91
    