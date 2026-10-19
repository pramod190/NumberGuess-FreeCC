#!/bin/bash
set -euo pipefail

PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"
TEST_USERNAME="run_test_user____$(printf '%05d' "$(( $$ % 100000 ))")"

cleanup() {
  user_id=$($PSQL "SELECT user_id FROM users WHERE username = '$TEST_USERNAME';")
  if [[ -n $user_id ]]; then
    $PSQL "DELETE FROM games WHERE user_id = $user_id;" > /dev/null
    $PSQL "DELETE FROM users WHERE user_id = $user_id;" > /dev/null
  fi
}
trap cleanup EXIT

[[ ${#TEST_USERNAME} -eq 22 ]]
output=$({ printf '%s\n' "$TEST_USERNAME" "not-an-integer" 1001; seq 1 1000; } | ./number_guess.sh)
grep -Fq "Welcome, $TEST_USERNAME! It looks like this is your first time here." <<< "$output"
grep -Fq "That is not an integer, guess again:" <<< "$output"
grep -Fq "It's lower than that, guess again:" <<< "$output"
grep -Fq "It's higher than that, guess again:" <<< "$output"
best=$(sed -nE 's/You guessed it in ([0-9]+) tries\..*/\1/p' <<< "$output")
[[ -n $best ]]

saved=$($PSQL "SELECT COUNT(*), MIN(number_guesses) FROM games JOIN users USING (user_id) WHERE username = '$TEST_USERNAME';")
[[ $saved == "1|$best" ]]

returning_output=$({ printf '%s\n' "$TEST_USERNAME"; seq 1 1000; } | ./number_guess.sh)
grep -Fq "Welcome back, $TEST_USERNAME! You have played 1 games, and your best game took $best guesses." <<< "$returning_output"
