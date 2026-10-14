#!/bin/bash

PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align"

printf 'Enter your username:\n'
read -r username
username_sql=$(printf '%s' "$username" | sed "s/'/''/g")

user_id=$($PSQL -c "SELECT user_id FROM users WHERE username = '$username_sql';")

if [[ -z $user_id ]]; then
	$PSQL -c "INSERT INTO users(username) VALUES ('$username_sql');" > /dev/null
	user_id=$($PSQL -c "SELECT user_id FROM users WHERE username = '$username_sql';")
	printf 'Welcome, %s! It looks like this is your first time here.\n' "$username"
else
	existing_username=$($PSQL -c "SELECT username FROM users WHERE user_id = $user_id;")
	stats=$($PSQL -c "SELECT COUNT(*), MIN(number_of_guesses) FROM games WHERE user_id = $user_id;")
	games_played=${stats%%|*}
	best_game=${stats#*|}
	printf 'Welcome back, %s! You have played %s games, and your best game took %s guesses.\n' \
		"$existing_username" "$games_played" "$best_game"
fi

secret_number=$(( RANDOM % 1000 + 1 ))
number_of_guesses=0

printf 'Guess the secret number between 1 and 1000:\n'
while read -r guess; do
	if [[ ! $guess =~ ^-?[0-9]+$ ]]; then
		printf 'That is not an integer, guess again:\n'
		continue
	fi

	number_of_guesses=$((number_of_guesses + 1))

	if ((guess == secret_number)); then
		printf 'You guessed it in %s tries. The secret number was %s. Nice job!\n' \
			"$number_of_guesses" "$secret_number"
		$PSQL -c "INSERT INTO games(user_id, number_of_guesses) VALUES ($user_id, $number_of_guesses);" > /dev/null
		break
	elif ((guess > secret_number)); then
		printf "It's lower than that, guess again:\n"
	else
		printf "It's higher than that, guess again:\n"
	fi
done
