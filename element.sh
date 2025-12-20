#!/bin/bash

PSQL="psql --username=freecodecamp --dbname=periodic_table -t --no-align -c"

if [[ -z $1 ]]
then
  echo "Please provide an element as an argument."
  exit
fi

# Determine search condition
if [[ $1 =~ ^[0-9]+$ ]]
then
  CONDITION="e.atomic_number = $1"
else
  CONDITION="e.symbol = INITCAP('$1') OR e.name = INITCAP('$1')"
fi

RESULT=$($PSQL "SELECT CONCAT_WS('|', e.atomic_number, e.name, e.symbol, replace(t.type, E'\\n', ' '), p.atomic_mass, p.melting_point_celsius, p.boiling_point_celsius) 
FROM elements e 
JOIN properties p USING(atomic_number) 
JOIN types t USING(type_id) 
WHERE $CONDITION" | tr -d '\r')

if [[ -z $RESULT ]]
then
  echo "I could not find that element in the database."
  exit
fi

IFS="|" read ATOMIC_NUMBER NAME SYMBOL TYPE MASS MELT BOIL <<< "$RESULT"

# Trim whitespace from fields
trim(){ echo "$1" | tr -d '\r\n' | sed -E 's/^[[:space:]]+|[[:space:]]+$//g'; }
ATOMIC_NUMBER=$(trim "$ATOMIC_NUMBER")
NAME=$(trim "$NAME")
SYMBOL=$(trim "$SYMBOL")
TYPE=$(trim "$TYPE")
MASS=$(trim "$MASS")
MELT=$(trim "$MELT")
BOIL=$(trim "$BOIL")

# Remove any embedded newlines that may remain
NAME=${NAME//$'\n'/}
SYMBOL=${SYMBOL//$'\n'/}
TYPE=${TYPE//$'\n'/}
MASS=${MASS//$'\n'/}
MELT=${MELT//$'\n'/}
BOIL=${BOIL//$'\n'/}

# Remove trailing zeros from decimal mass (e.g. 1.0080 -> 1.008)
if [ -n "$MASS" ]; then
  MASS=$(printf "%g" "$MASS")
fi

echo "The element with atomic number $ATOMIC_NUMBER is $NAME ($SYMBOL). It's a $TYPE, with a mass of $MASS amu. $NAME has a melting point of $MELT celsius and a boiling point of $BOIL celsius."