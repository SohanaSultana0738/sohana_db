#!/bin/bash

PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -q -c"


echo "Enter your username:"
read USERNAME

# Check if user exists
USER_INFO=$($PSQL "SELECT user_id, games_played, best_game FROM users WHERE username='$USERNAME'")

if [[ -z $USER_INFO ]]
then
  # New user
  echo "Welcome, $USERNAME! It looks like this is your first time here."
  $PSQL "INSERT INTO users(username) VALUES('$USERNAME')"
  USER_ID=$($PSQL "SELECT user_id FROM users WHERE username='$USERNAME'")
  GAMES_PLAYED=0
  BEST_GAME=0

else
  # Returning user
  IFS="|" read USER_ID GAMES_PLAYED BEST_GAME <<< "$USER_INFO"

  USER_ID=$(echo $USER_ID | xargs)
  GAMES_PLAYED=$(echo $GAMES_PLAYED | xargs)
  BEST_GAME=$(echo $BEST_GAME | xargs)

  # Handle NULL best_game
  if [[ -z $BEST_GAME ]]; then
    BEST_GAME=0
  fi

  DB_USERNAME=$($PSQL "SELECT username FROM users WHERE user_id=$USER_ID" | xargs)

  echo "Welcome back, $DB_USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
fi

# Generate secret number
SECRET=$((RANDOM % 1000 + 1))
TRIES=0

echo "Guess the secret number between 1 and 1000:"

while true
do
  read GUESS

  # Validate integer
  if [[ ! $GUESS =~ ^[0-9]+$ ]]
  then
    echo "That is not an integer, guess again:"
    continue
  fi

  ((TRIES++))

  if [[ $GUESS -eq $SECRET ]]
  then
    echo "You guessed it in $TRIES tries. The secret number was $SECRET. Nice job!"

    # Update games_played
    $PSQL "UPDATE users SET games_played = games_played + 1 WHERE user_id=$USER_ID"

    # Update best_game if needed
    if [[ $BEST_GAME -eq 0 || $TRIES -lt $BEST_GAME ]]
    then
      $PSQL "UPDATE users SET best_game=$TRIES WHERE user_id=$USER_ID"
    fi

    break

  elif [[ $GUESS -gt $SECRET ]]
  then
    echo "It's lower than that, guess again:"
  else
    echo "It's higher than that, guess again:"
  fi
done
