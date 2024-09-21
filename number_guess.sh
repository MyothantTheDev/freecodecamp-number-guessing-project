#!/bin/bash

# variable to query database
PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

MAIN() {
  # promp player for username
  echo -e "\nEnter your username:"
  read USERNAME

  GET_USER_OR_REGISTER $USERNAME
  PLAY_GAME $?
}

GET_USER_OR_REGISTER() {
  # GET USER ID
  USER_ID=$($PSQL "SELECT user_id FROM users WHERE username = '$1';")
  if [[ -z $USER_ID ]]
  then
    # REGISTER USER
    INSERT_USER_RESULT=$($PSQL "INSERT INTO users(username) VALUES ('$1');")
    if [[ $INSERT_USER_RESULT == "INSERT 0 1" ]]
    then
      # GET USER ID
      USER_ID=$($PSQL "SELECT user_id FROM users WHERE username = '$1';")
      echo "Welcome, $1! It looks like this is your first time here."
    fi
  else
    # GET GAME RESULT AND NUMBER OF GAMES
    BEST_GAME=$($PSQL "SELECT MIN(number_of_guesses) FROM games LEFT JOIN users USING(user_id) WHERE user_id = $USER_ID;")
    GAMES_PLAYED=$($PSQL "SELECT COUNT(game_id) FROM games LEFT JOIN users USING(user_id) WHERE user_id = $USER_ID;")
    echo "Welcome back, $1! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
  fi
  return $USER_ID
}

PLAY_GAME() {
  # RAMDON NUMBER
  SECRET_NUMBER=$(( RANDOM % 1000 + 1 ))
  
  # variable to store number of guesses/tries
  GUESS_COUNT=0

  # prompt first guess
  echo -e "\nGuess the secret number between 1 and 1000:"
  read USER_GUESS

  # loop to prompt user to guess until correct
  while [[ $USER_GUESS != $SECRET_NUMBER ]]
  do
    
    # check guess is valid/an integer
    if [[ ! $USER_GUESS =~ ^[0-9]+$ ]]
      then
        # request valid guess
        echo -e "\nThat is not an integer, guess again:"
        read USER_GUESS
        # update guess count
        ((GUESS_COUNT++))
      
      # if its a valid guess
      else
        # check inequalities and give hint
        if [[ $USER_GUESS < $SECRET_NUMBER ]]
          then
            echo -e "\nIt's higher than that, guess again:"
            read USER_GUESS
            # update guess count
            ((GUESS_COUNT++))
          else 
            echo -e "\nIt's lower than that, guess again:"
            read USER_GUESS
            #update guess count
            ((GUESS_COUNT++))
        fi  
    fi

  done

  # loop ends when guess is correct so, update guess
  ((GUESS_COUNT++))

  # add result to game history/database
  INSERT_GAME_RESULT=$($PSQL "INSERT INTO games(user_id, number_of_guesses) VALUES ($1, $GUESS_COUNT);")

  # winning message
  echo "You guessed it in $GUESS_COUNT tries. The secret number was $SECRET_NUMBER. Nice job!"
}

MAIN