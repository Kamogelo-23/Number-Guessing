#!/bin/bash

PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

# ensure table exists (created if missing)
$($PSQL "CREATE TABLE IF NOT EXISTS users(username VARCHAR(22) PRIMARY KEY, games_played INT, best_game INT);")

echo "Enter your username:"
read USERNAME

USER_IN_DB=$($PSQL "SELECT username FROM users WHERE username='$USERNAME';")

if [[ -z $USER_IN_DB ]]; then
  echo "Welcome, $USERNAME! It looks like this is your first time here."
else
  GAMES_PLAYED=$($PSQL "SELECT games_played FROM users WHERE username='$USERNAME';")
  BEST_GAME=$($PSQL "SELECT best_game FROM users WHERE username='$USERNAME';")
  echo "Welcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
fi

SECRET=$(( RANDOM % 1000 + 1 ))
echo "Guess the secret number between 1 and 1000:"
GUESS_COUNT=0

while true; do
  read GUESS
  GUESS=$(echo "$GUESS" | sed 's/^ *//;s/ *$//')
  if ! [[ $GUESS =~ ^[0-9]+$ ]]; then
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

    if [[ -z $USER_IN_DB ]]; then
      $PSQL "INSERT INTO users(username,games_played,best_game) VALUES('$USERNAME',1,$GUESS_COUNT);" >/dev/null
    else
      $PSQL "UPDATE users SET games_played = games_played + 1, best_game = CASE WHEN best_game IS NULL OR $GUESS_COUNT < best_game THEN $GUESS_COUNT ELSE best_game END WHERE username = '$USERNAME';" >/dev/null
    fi
    break
  fi
done
