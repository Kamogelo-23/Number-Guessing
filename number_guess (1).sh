#!/bin/bash

# number guessing game script — stores results in the number_guess database
PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

echo "Enter your username:"
read USERNAME
# trim surrounding whitespace
USERNAME="$(echo -n "$USERNAME" | sed 's/^ *//; s/ *$//')"

# check if user exists
USER_ID=$($PSQL "SELECT user_id FROM users WHERE username='$USERNAME';")

if [[ -z $USER_ID ]]; then
  # new user
  $PSQL "INSERT INTO users(username) VALUES('$USERNAME');" >/dev/null
  USER_ID=$($PSQL "SELECT user_id FROM users WHERE username='$USERNAME';")
  echo "Welcome, $USERNAME! It looks like this is your first time here."
else
  GAMES_PLAYED=$($PSQL "SELECT COUNT(*) FROM games WHERE user_id=$USER_ID;")
  if [[ $GAMES_PLAYED -eq 0 ]]; then
    echo "Welcome, $USERNAME! It looks like this is your first time here."
  else
    BEST_GAME=$($PSQL "SELECT MIN(guesses) FROM games WHERE user_id=$USER_ID;")
    echo "Welcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
  fi
fi

# game
SECRET=$(( RANDOM % 1000 + 1 ))
GUESS_COUNT=0

echo "Guess the secret number between 1 and 1000:"
while read GUESS; do
  # validate integer
  if [[ ! $GUESS =~ ^[0-9]+$ ]]; then
    echo "That is not an integer, guess again:"
    continue
  fi

  ((GUESS_COUNT++))

  if (( GUESS > SECRET )); then
    echo "It's lower than that, guess again:"
  elif (( GUESS < SECRET )); then
    echo "It's higher than that, guess again:"
  else
    echo "You guessed it in $GUESS_COUNT tries. The secret number was $SECRET. Nice job!"
    # save game
    $PSQL "INSERT INTO games(user_id, guesses) VALUES($USER_ID, $GUESS_COUNT);" >/dev/null
    break
  fi
done