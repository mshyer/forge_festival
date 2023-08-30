# FORGE FESTIVAL #

## DESCRIPTION ##
Forge Festival is a fantasy-themed CRUD web application. It is a website that allows you to create collections ("teams" AKA "forge teams"), and objects ("items") for each collection. There is a One-to-Many relationship between teams and items. 

## PREMISE ##
Dwarves (well known to be expert miners and smiths) gather from across the land once a decade to compete in FORGE FESTIVAL. During this competition, "forge teams" compete to create the best items. Created items are judged by two categories: quality and beauty. 

This website is designed to keep track of the teams, items, and their respective scores, during the competition. 

## SORTING TEAMS AND ITEMS ##
Teams and items on the website are sorted according to *score*. Score is calculated as follows:
"Quality" and "Beauty" for items are measured on an integer scale from 1-10. However, as Dwarves have very high standards, only values above 6 count towards the score. Each value above 6 awards 1 point. For example, a sword of quality 8 and beauty 7 awards 3 points. Armor of quality 1 and beauty 8 awards two points. There is no difference in the way different categories of items are scored (for example, daggers are treated the same as battleaxes, and both are treated the same as shields). The maximum assessed score for an item is 8 (if it has quality 10 and beauty 10). Items with assessed score 0 are still listed.

Items are sorted according to assessed item score (desc) and then name (desc). EX an item with score 2 will be listed before an item of score 1. If items have the same score, the name beginning with letter "z" will appear before the letter "a".

Teams are sorted in a similar way. Teams with the highest total score (the sum of their item scores) are listed first. Teams with the same score are then sorted in reverse alphabetical order. Max 5 items/teams are listed per page. 

## APPLICATION STRUCTURE ##
The main sinatra route code is contained in the 'forge_festival.rb' file. The code for interacting with the database and PG objects is contained in the "database_persistence.rb" file. The code related to validations required by the test instructions is in the "validation.rb" file. The login info is stored in the "users" folder, which contains a YAML file that stores username/password info. 

## RUNNING THE APPLICATION ##
After downloading all the files to your system, first run `bundle install` to install all required gems and gem dependencies. After the gems are successfully installed, then run `bundle exec ruby forge_festival.rb`. The application will automatically create the database "forge_festival" (if it doesn't already exist) and populate it with seed data. 

If for some reason, the program fails at automatically setting up the database, you will need to manually create a database "forge_festival", and set it up with the schema defined in the `forge_festival.sql` file. You can create the database by running the command `createdb forge_festival`. You will then need to populate the database with data by running `psql -d forge_festival < forge_festival.sql`

## LOGGING IN ##
Most app functionality can only be accessed after logging in. To log in, use the username: "admin" and password: "123456"

## DEVELOPMENT ENVIRONMENT DETAILS ##
Ruby version: 3.1.2
Personal computer info: ARM Mac M1
Browser used to test: Chrome: Version 106.0.5249.119 (Official Build) (arm64)
Postgres database info: PostgreSQL 14.5 (Homebrew) on aarch64-apple-darwin21.6.0, compiled by Apple clang version 13.1.6 (clang-1316.0.21.2.5), 64-bit

### A NOTE ON NAMES ###
I used https://www.fantasynamegenerators.com to help generate names for the seed data. You can generate dwarf names using: https://www.fantasynamegenerators.com/dwarf-names.php. You can also use their website to generate weapon names, armor names and blacksmith names, etc. 

### TESTING NOTES FOR YOUR CONVENIENCE ###
Custom error messages are displayed for most string inputs if the user inputs more than 100 characters. Error messages are also displayed if the user tries to choose a non-unique name for items or teams.
Numeric inputs are validated in Ruby code, but the user is first prevented from inputting values out of range (1-10) using HTML min/max values. # forge_festival
