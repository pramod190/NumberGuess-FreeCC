#!/bin/bash

PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

echo "Enter your username:"
read -r USERNAME
USERNAME_SQL=$(printf '%s' "$USERNAME" | sed "s/'/''/g")

USER_DATA=$($PSQL "SELECT user_id, (SELECT COUNT(*) FROM games WHERE user_id = users.user_id), COALESCE((SELECT MIN(number_guesses) FROM games WHERE user_id = users.user_id), 0) FROM users WHERE username = '$USERNAME_SQL';")

if [[ -z $USER_DATA ]]; then
	$PSQL "INSERT INTO users(username) VALUES ('$USERNAME_SQL');" > /dev/null
	USER_ID=$($PSQL "SELECT user_id FROM users WHERE username = '$USERNAME_SQL';")
	echo "Welcome, $USERNAME! It looks like this is your first time here."
else
	IFS='|' read -r USER_ID GAMES_PLAYED BEST_GAME <<< "$USER_DATA"
	echo "Welcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
fi

SECRET_NUMBER=$((RANDOM % 1000 + 1))
NUMBER_OF_GUESSES=0

echo "Guess the secret number between 1 and 1000:"
read -r GUESS

while true; do
	if [[ ! $GUESS =~ ^-?[0-9]+$ ]]; then
		echo "That is not an integer, guess again:"
		read -r GUESS
		continue
	fi

	if [[ $GUESS == -* ]]; then
		GUESS_NUMBER=$((-10#${GUESS#-}))
	else
		GUESS_NUMBER=$((10#$GUESS))
	fi
	NUMBER_OF_GUESSES=$((NUMBER_OF_GUESSES + 1))

	if (( GUESS_NUMBER == SECRET_NUMBER )); then
		$PSQL "INSERT INTO games(user_id, number_guesses) VALUES ($USER_ID, $NUMBER_OF_GUESSES);" > /dev/null
		echo "You guessed it in $NUMBER_OF_GUESSES tries. The secret number was $SECRET_NUMBER. Nice job!"
		break
	elif (( GUESS_NUMBER > SECRET_NUMBER )); then
		echo "It's lower than that, guess again:"
	else
		echo "It's higher than that, guess again:"
	fi
	read -r GUESS
done
