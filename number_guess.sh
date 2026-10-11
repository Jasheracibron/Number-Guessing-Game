#!/bin/bash

PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

echo "Enter your username:"
read -r USERNAME

USERNAME_SQL=$(printf '%s' "$USERNAME" | sed "s/'/''/g")
USER_ID=$($PSQL "SELECT user_id FROM users WHERE username = '$USERNAME_SQL'")

if [[ -z $USER_ID ]]; then
	$PSQL "INSERT INTO users(username) VALUES('$USERNAME_SQL')" > /dev/null
	USER_ID=$($PSQL "SELECT user_id FROM users WHERE username = '$USERNAME_SQL'")
	echo "Welcome, $USERNAME! It looks like this is your first time here."
else
	USER_STATS=$($PSQL "SELECT COUNT(*) || '|' || MIN(number_of_guesses) FROM games WHERE user_id = $USER_ID")
	IFS='|' read -r GAMES_PLAYED BEST_GAME <<< "$USER_STATS"
	echo "Welcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
fi

SECRET_NUMBER=$(( RANDOM % 1000 + 1 ))
NUMBER_OF_GUESSES=0

echo "Guess the secret number between 1 and 1000:"
while read -r GUESS; do
	if [[ ! $GUESS =~ ^[+-]?[0-9]+$ ]]; then
		echo "That is not an integer, guess again:"
		continue
	fi

	if [[ $GUESS == -* ]]; then
		GUESS_SIGN=-
		GUESS_DIGITS=${GUESS#-}
	elif [[ $GUESS == +* ]]; then
		GUESS_SIGN=+
		GUESS_DIGITS=${GUESS#+}
	else
		GUESS_SIGN=+
		GUESS_DIGITS=$GUESS
	fi

	while [[ ${#GUESS_DIGITS} -gt 1 && ${GUESS_DIGITS:0:1} == 0 ]]; do
		GUESS_DIGITS=${GUESS_DIGITS:1}
	done
	((NUMBER_OF_GUESSES++))

	if [[ $GUESS_SIGN == - && $GUESS_DIGITS != 0 ]]; then
		echo "It's higher than that, guess again:"
	elif [[ $GUESS_DIGITS == "$SECRET_NUMBER" ]]; then
		echo "You guessed it in $NUMBER_OF_GUESSES tries. The secret number was $SECRET_NUMBER. Nice job!"
		$PSQL "INSERT INTO games(user_id, number_of_guesses) VALUES($USER_ID, $NUMBER_OF_GUESSES)" > /dev/null
		break
	elif (( ${#GUESS_DIGITS} > ${#SECRET_NUMBER} )) || { (( ${#GUESS_DIGITS} == ${#SECRET_NUMBER} )) && [[ $GUESS_DIGITS > $SECRET_NUMBER ]]; }; then
		echo "It's lower than that, guess again:"
	else
		echo "It's higher than that, guess again:"
	fi
done