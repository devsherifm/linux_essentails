#!/usr/bin/env bash
# Master Bash Scripting Tutorial - (strict, modular, interactive, robust)
# - Each main topic is a function: section_*
# - main() calls them in the exact order you requested
# - run_section wrapper prints boxed header, numbered explanations, runs examples,
#   captures failures and continues to next section.
# - Interactive: Enter to continue, 'q' to skip remaining content in current section,
#   'Q' to quit the whole script.
#
# USAGE:
#   chmod +x <script_name>
#   ./<script_name> arg1 arg2 .. arg9
#
# NOTE: This script does NOT enable set -e because we want to continue after failures.
#       Instead we run each section in a controlled wrapper and report any non-zero status.

# ---- Color Definitions (ANSI Escape Codes) ----
# These work on most terminals (CentOS, Ubuntu, etc.). Use NC to reset.
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Colorized echo helper for consistent output
cecho() {
  local color="$1"; shift
  echo -e "${!color}$*${NC}"
}

# ---- Safety / basic env ----
set -u
cecho GREEN "The script above line using the command set -u To Treat unset variables as an error and exit immediately. Helps catch typos and undefined variables. \n"
IFS=$'\n\t'
cecho GREEN "The script above line using the command "IFS=\$'\\n\\t'" To Set Internal Field Separator (IFS) to newline and tab only. Prevents word splitting on spaces.\n"
set +e          # Do NOT exit on errors (continue execution)
	
# ---- Global vars ----
TMP_LINES="./temp_shell_demo_lines_$$.txt"
cecho GREEN "The script uses local temp file: $TMP_LINES (PID: $$)\n"
CLEANUP_ITEMS=("$TMP_LINES")  # Array of items (files) to clean up when the script exits.

# store global copies before calling
SCRIPT_ARGS="$@" # Store all script arguments in a single variable for later use.
SCRIPT_ARG_COUNT="$#" # Store the number of arguments passed to the script.
FILE_NAME="$0" #Store the name of the current script.

# ---- Cleanup/trap ----
cleanup() {
  # Remove temp files created by this script session
  for f in "${CLEANUP_ITEMS[@]}"; do
    [[ -e "$f" ]] && rm -f "$f"
  done
  # Remove known demo artifacts if they exist in current dir
  rm -f ./test_*.sh ./test_*.txt ./demo_file.txt ./error.txt ./combined.txt ./input.txt ./output.txt ./redir_test.txt ./fd_log.txt ./log.txt ./sample.txt ./copy.txt ./moved.txt ./sorted*.txt ./errors_demo.log ./bad_demo.sh ./script ./password ./key.txt ./data* ./tmpxxxxxx ./tmprandom ./backpipe ./suconnect ./temp_shell_demo*
  rm -rf ./demo_dir ./my ./repo* ./inhere ./myfolder ./task_*
}
trap cleanup EXIT # Register the cleanup function to run automatically when the script exits.

# ---- UI helpers ----
box_header() {
  local title="$1"
  local width=60
  local title_len=${#title}
  local padding=$(( (width - title_len) / 2 ))
  local remainder=$(( width - padding - title_len ))

  echo
  cecho BLUE   "╔$(printf '═%.0s' $(seq 1 $width))╗"
  # Use printf to create the centered line with borders. 
  # Note: ANSI codes in 'title' might mess up length calc, but we assume raw text here.
  # We construct the line carefully.
  printf "${BLUE}║%*s${BOLD}${WHITE}%s${NC}${BLUE}%*s║\n" $padding "" "$title" $remainder ""
  cecho BLUE   "╚$(printf '═%.0s' $(seq 1 $width))╝"
  echo
}

print_toc() {
  box_header "MASTER BASH SCRIPTING TUTORIAL"
  cecho CYAN "Table of Contents - The following sections will be covered interactivey:"
  echo
  local idx=1
  for entry in "${SECTION_LIST[@]}"; do
    local title="${entry%%:*}"
    # Pretty print with index
    printf "${GREEN}%2d.${NC} %s\n" "$idx" "$title"
    ((idx++))
  done
  echo
  _prompt_action "Press ENTER to start the tutorial..." || return
}
_prompt_action() {
  # Optional custom prompt, default to generic
  local prompt="${1:-"Press Enter to continue, 'q' to skip this section, 'Q' to quit, or enter topic number (1-${#SECTION_LIST[@]}): "}"
  local ans # Local variable to store user input
  cecho CYAN "$prompt"
  read -r ans || true

  if [[ "$ans" == "Q" ]]; then
    cecho RED "Aborting as requested."
    exit 0
  elif [[ "$ans" == "q" ]]; then
    return 50 # Return 50 for "Skip Section"
  elif [[ "$ans" =~ ^[0-9]+$ ]]; then
    # Numeric input -> Jump
    if (( ans >= 1 && ans <= ${#SECTION_LIST[@]} )); then
       JUMP_TO_TARGET=$ans
       cecho YELLOW "Jumping to section $ans..."
       return 1 # Return "skip" code to exit current section immediately
    else
       cecho RED "Invalid section number: $ans. Continuing..."
       return 0
    fi
  else
    return 0
  fi
}

run_section() {
  local title="$1"; shift
  local func="$1"; shift

  box_header "$title"

  cecho WHITE "1) Explanation / subtopics will be shown first."
  echo
  
  # Run the section function
  "$func"
  local func_ret=$?

  # Check if a jump was requested
  if [[ -n "${JUMP_TO_TARGET:-}" ]]; then
      # Jump requested: exit immediately, no warnings, no prompts
      return 0
  fi

  if (( func_ret == 0 )); then
    echo
    cecho GREEN "✔ Section completed: $title"
    echo
    if ! _prompt_action; then
       cecho YELLOW "Skipping remaining steps..."
    fi
  elif (( func_ret == 50 )); then
    echo
    cecho YELLOW "⏩ Section skipped: $title"
    # Do NOT prompt again
  else
    echo
    cecho YELLOW "⚠️  Section failed (code $func_ret) but continuing: $title"
    echo
    if ! _prompt_action; then
       cecho YELLOW "Skipping remaining steps..."
    fi
  fi
}


# ---- Section implementations ----

section_loops_conditions() {
  cecho BLUE "--------------------"
  cecho BOLD "1️⃣ IF Statement Example"
  cecho BLUE "--------------------"
  cat << 'EOF'
Example:
num=10
if [ $num -gt 5 ]; then
    echo "Number is greater than 5"
fi
EOF
  echo
  read -p "Press ENTER to run the example..."
  num=10
  if [ $num -gt 5 ]; then
      cecho GREEN "Output: Number is greater than 5"
  fi
  _prompt_action || return

  cecho BLUE "--------------------"
  cecho BOLD "2️⃣ IF-ELSE Example"
  cecho BLUE "--------------------"
  cat << 'EOF'
Example:
num=3
if [ $num -gt 5 ]; then
    echo "Number is greater than 5"
else
    echo "Number is 5 or less"
fi
EOF
  read -p "Press ENTER to run the example..."
  num=3
  if [ $num -gt 5 ]; then
      cecho GREEN "Output: Number is greater than 5"
  else
      cecho GREEN "Output: Number is 5 or less"
  fi
  _prompt_action || return

  cecho BLUE "--------------------"
  cecho BOLD "3️⃣ IF-ELIF-ELSE Example"
  cecho BLUE "--------------------"
  cat << 'EOF'
Example:
num=5
if [ $num -gt 10 ]; then
    echo "Greater than 10"
elif [ $num -eq 10 ]; then
    echo "Equal to 10"
else
    echo "Less than 10"
fi
EOF
  read -p "Press ENTER to run the example..."
  num=5
  if [ $num -gt 10 ]; then
      cecho GREEN "Output: Greater than 10"
  elif [ $num -eq 10 ]; then
      cecho GREEN "Output: Equal to 10"
  else
      cecho GREEN "Output: Less than 10"
  fi
  _prompt_action || return

  cecho BLUE "--------------------"
  cecho BOLD "4️⃣ Nested IF Example"
  cecho BLUE "--------------------"
  cat << 'EOF'
Example:
num=7
if [ $num -gt 5 ]; then
    if [ $num -lt 10 ]; then
        echo "Number is between 5 and 10"
    fi
fi
EOF
  read -p "Press ENTER to run the example..."
  num=7
  if [ $num -gt 5 ]; then
      if [ $num -lt 10 ]; then
          cecho GREEN "Output: Number is between 5 and 10"
      fi
  fi
  _prompt_action || return

  cecho BLUE "--------------------"
  cecho BOLD "5️⃣ FOR Loop Example 1.1 with list of items"
  cecho BLUE "--------------------"
  cat << 'EOF'
Example:
for i in 1 2 3 4 5
do
    echo "Count: $i"
done
EOF
  read -p "Press ENTER to run the example..."
  for i in 1 2 3 4 5
  do
      cecho GREEN "Output: Count: $i"
  done
  _prompt_action || return

  cecho BLUE "--------------------"
  cecho BOLD "5️⃣ FOR Loop Example 1.2 with range"
  cecho BLUE "--------------------"
  cat << 'EOF'
Example:
for ((c=1;c<=5;c++))
do
 echo "Welcome $c times"
done
EOF
  read -p "Press ENTER to run the example..."
  for ((c=1;c<=5;c++))
  do
   cecho GREEN "Welcome $c times"
  done
  _prompt_action || return

  cecho BLUE "--------------------"
  cecho BOLD "5️⃣ FOR Loop Example 1.3 Brace expansion with step"
  cecho BLUE "--------------------"
  cat << 'EOF'
Example:
for i in {1..10..2}
do
  echo "  brace -> $i"
done
EOF
  read -p "Press ENTER to run the example..."
  for i in {1..10..2}
  do
    cecho GREEN "  brace -> $i"
  done
  _prompt_action || return

  cecho BLUE "--------------------"
  cecho BOLD "5️⃣ FOR Loop Example 1.4 Infinite loop auto-break after iteration limit"
  cecho BLUE "--------------------"
  cat << 'EOF'
Example:
  j=0
  for (( ; ; )); do
    echo "  infinite-loop iter $j"
    j=$((j+1))
    if [ $j -ge 3 ]; then
      echo "  breaking infinite loop at $j"
      break
    fi
  done
EOF
  read -p "Press ENTER to run the example..."
  j=0
  for (( ; ; )); do
    cecho GREEN "  infinite-loop iter $j"
    j=$((j+1))
    if [ $j -ge 3 ]; then
      cecho GREEN "  breaking infinite loop at $j"
      break
    fi
  done
  _prompt_action || return

  cecho BLUE "--------------------"
  cecho BOLD "6️⃣ WHILE Loop Example"
  cecho BLUE "--------------------"
  cat << 'EOF'
Example:
count=1
while [ $count -le 5 ]
do
    echo "Count: $count"
    ((count++))
done
EOF
  read -p "Press ENTER to run the example..."
  count=1
  while [ $count -le 5 ]
  do
      cecho GREEN "Output: Count: $count"
      ((count++))
  done
  _prompt_action || return

  cecho BLUE "--------------------"
  cecho BOLD "7️⃣ CASE Statement Example"
  cecho BLUE "--------------------"
  cat << 'EOF'
Example:
read -p "Enter a number (1-3): " num
case $num in
    1) echo "You chose One" ;;
    2) echo "You chose Two" ;;
    3) echo "You chose Three" ;;
    *) echo "Invalid choice" ;;
esac
EOF
  read -p "Press ENTER to run the example..."
  read -p "Enter a number (1-3): " num
  case $num in
      1) cecho GREEN "Output: You chose One" ;;
      2) cecho GREEN "Output: You chose Two" ;;
      3) cecho GREEN "Output: You chose Three" ;;
      *) cecho RED "Output: Invalid choice" ;;
  esac
  _prompt_action || return

  cecho GREEN "🎉 Congratulations! You’ve completed the Loops & Conditions Section."
  cecho CYAN "Next: Functions & Arrays (coming soon...)"
  cecho BLUE "==========================================="
}

section_system_vars() {
  cecho BLUE "--------------------"
  cecho BOLD "1️⃣ System / Special Variables Overview"
  cecho BLUE "--------------------"
  cat << 'EOF'
These special variables are automatically available in every Bash shell:

  $@        → all positional arguments
  $#        → number of positional args
  $?        → exit status of last command
  $$        → PID of this script
  $SECONDS  → seconds since the shell started
  $RANDOM   → random number
  $LINENO   → current script line number
  $USER     → current logged-in user
  $HOSTNAME → system hostname
  $PATH     → system PATH variable
EOF
  read -p "Press ENTER to see the examples..."
  _prompt_action || return

  echo
  cecho BLUE "--------------------"
  cecho BOLD "2️⃣ Displaying Current System Variable Values"
  cecho BLUE "--------------------"
  cat << 'EOF'
Example:
  echo "File name (\$0): ${FILE_NAME:-0}"
  echo "All args (\$@): ${SCRIPT_ARGS:-<none>}"
  echo "Arg count (\$#): ${SCRIPT_ARG_COUNT:-0}"
  echo "PID (\$$): $$"
  echo "SECONDS: ${SECONDS:-0}"
  echo "RANDOM: $RANDOM"
  echo "LINENO: ${LINENO}"
  echo "USER: ${USER:-$(whoami 2>/dev/null || echo unknown)}"
  echo "HOSTNAME: ${HOSTNAME:-$(hostname 2>/dev/null || echo unknown)}"
  echo "PATH: $PATH"
EOF
  read -p "Press ENTER to run the example..."
  _prompt_action || return

  echo
  cecho GREEN "Output:"
  cecho GREEN "a) File name (\$0): ${FILE_NAME:-0}"
  cecho GREEN "b) All args (\$@): ${SCRIPT_ARGS:-<none>}"
  cecho GREEN "c) Arg count (\$#): ${SCRIPT_ARG_COUNT:-0}"
  cecho GREEN "d) PID (\$$): $$"
  cecho GREEN "e) SECONDS: ${SECONDS:-0}"
  cecho GREEN "f) RANDOM: $RANDOM"
  cecho GREEN "g) LINENO (current): ${LINENO}"
  cecho GREEN "h) USER: ${USER:-$(whoami 2>/dev/null || echo unknown)}"
  cecho GREEN "i) HOSTNAME: ${HOSTNAME:-$(hostname 2>/dev/null || echo unknown)}"
  cecho GREEN "j) PATH: $PATH"
  _prompt_action || return
}

section_parameter_expansion_regex() {
  cecho BLUE "--------------------"
  cecho BOLD "1️⃣ Parameter Expansion: substring, replace, and length"
  cecho BLUE "--------------------"
  cat << 'EOF'
Example:
  s="foobarbaz"
  echo "Original string: $s"
  echo "Substring from 3 (3 chars): ${s:3:3}"
  echo "Replace first foo → FOO: ${s/foo/FOO}"
  echo "Replace all a → @: ${s//a/@}"
  echo "Remove prefix up to first b: ${s#*b}"
  echo "Remove suffix from last b: ${s%%b*}"
  echo "String length: ${#s}"
EOF
  read -p "Press ENTER to run the example..."
  _prompt_action || return
  s="foobarbaz"
  cecho GREEN "a) Original string: $s"
  cecho GREEN "b) Substring from 3 (3 chars): ${s:3:3}"
  cecho GREEN "c) Replace first foo → FOO: ${s/foo/FOO}"
  cecho GREEN "d) Replace all a → @: ${s//a/@}"
  cecho GREEN "e) Remove prefix up to first b: ${s#*b}"
  cecho GREEN "f) Remove suffix from last b: ${s%%b*}"
  cecho GREEN "g) String length: ${#s}"
  _prompt_action || return

  echo
  cecho BLUE "--------------------"
  cecho BOLD "2️⃣ Regex match with =~"
  cecho BLUE "--------------------"
  cat << 'EOF'
Example:
  sample="abc123"
  if [[ $sample =~ ([0-9]+) ]]; then
      echo "Digits matched → ${BASH_REMATCH[1]}"
  else
      echo "No digits found"
  fi
EOF
  read -p "Press ENTER to run the example..."
  _prompt_action || return
  sample="abc123"
  if [[ $sample =~ ([0-9]+) ]]; then
      cecho GREEN "Digits matched → ${BASH_REMATCH[1]}"
  else
      cecho RED "No digits found"
  fi
  _prompt_action || return

  echo
  cecho BLUE "--------------------"
  cecho BOLD "3️⃣ String Tests: -n, -z, =, !="
  cecho BLUE "--------------------"
  cat << 'EOF'
Example:
  empty=""
  nonempty="Hello"

  if [ -z "$empty" ]; then echo "-z: empty string"; fi
  if [ -n "$nonempty" ]; then echo "-n: non-empty string"; fi
  if [ "$nonempty" = "Hello" ]; then echo "=: strings are equal"; fi
  if [ "$nonempty" != "World" ]; then echo "!=: strings are not equal"; fi
EOF
  read -p "Press ENTER to run the example..."
  _prompt_action || return
  empty=""
  nonempty="Hello"
  if [ -z "$empty" ]; then cecho GREEN "a) -z: empty string"; fi
  if [ -n "$nonempty" ]; then cecho GREEN "b) -n: non-empty string"; fi
  if [ "$nonempty" = "Hello" ]; then cecho GREEN "c) =: strings are equal"; fi
  if [ "$nonempty" != "World" ]; then cecho GREEN "d) !=: strings are not equal"; fi
  _prompt_action || return

  echo
  cecho BLUE "--------------------"
  cecho BOLD "4️⃣ Numeric Comparisons: -eq, -ne, -lt, -le, -gt, -ge"
  cecho BLUE "--------------------"
  cat << 'EOF'
Example:
  a=5; b=10
  if [ $a -eq $a ]; then echo "-eq: equal"; fi
  if [ $a -ne $b ]; then echo "-ne: not equal"; fi
  if [ $a -lt $b ]; then echo "-lt: less than"; fi
  if [ $b -gt $a ]; then echo "-gt: greater than"; fi
  if [ $a -le $b ]; then echo "-le: less or equal"; fi
  if [ $b -ge $a ]; then echo "-ge: greater or equal"; fi
EOF
  read -p "Press ENTER to run the example..."
  _prompt_action || return
  a=5; b=10
  if [ $a -eq $a ]; then cecho GREEN "a) -eq: equal"; fi
  if [ $a -ne $b ]; then cecho GREEN "b) -ne: not equal"; fi
  if [ $a -lt $b ]; then cecho GREEN "c) -lt: less than"; fi
  if [ $b -gt $a ]; then cecho GREEN "d) -gt: greater than"; fi
  if [ $a -le $b ]; then cecho GREEN "e) -le: less or equal"; fi
  if [ $b -ge $a ]; then cecho GREEN "f) -ge: greater or equal"; fi
  _prompt_action || return

  echo
  cecho BLUE "--------------------"
  cecho BOLD "5️⃣ File Tests: -e, -f, -d, -r, -w, -x, -s"
  cecho BLUE "--------------------"
  cat << 'EOF'
Example (create demo file first):
  cat << 'FILE' > demo_file.txt
sample text
FILE

  if [ -e demo_file.txt ]; then echo "-e: file exists"; fi
  if [ -f demo_file.txt ]; then echo "-f: is a regular file"; fi
  if [ -s demo_file.txt ]; then echo "-s: file is not empty"; fi
  if [ -r demo_file.txt ]; then echo "-r: readable"; fi
  if [ -w demo_file.txt ]; then echo "-w: writable"; fi
  if [ -x demo_file.txt ]; then echo "-x: executable"; fi
  if [ -d . ]; then echo "-d: current path is a directory"; fi
EOF
  read -p "Press ENTER to run the example..."
  _prompt_action || return
  cat << 'FILE' > demo_file.txt
sample text
FILE
  if [ -e demo_file.txt ]; then cecho GREEN "a) -e: file exists"; fi
  if [ -f demo_file.txt ]; then cecho GREEN "b) -f: is a regular file"; fi
  if [ -s demo_file.txt ]; then cecho GREEN "c) -s: file is not empty"; fi
  if [ -r demo_file.txt ]; then cecho GREEN "d) -r: readable"; fi
  if [ -w demo_file.txt ]; then cecho GREEN "e) -w: writable"; fi
  if [ -x demo_file.txt ]; then cecho GREEN "f) -x: executable"; fi
  if [ -d . ]; then cecho GREEN "g) -d: current path is a directory"; fi
  _prompt_action || return

  echo
  cecho BLUE "--------------------"
  cecho BOLD "6️⃣ Logical NOT and Combined Expressions"
  cecho BLUE "--------------------"
  cat << 'EOF'
Example:
  a=5; b=3
  if ! [ $a -lt $b ]; then echo "! : 5 is not less than 3"; fi
  if [ $a -gt 0 ] && [ $b -gt 0 ]; then echo "&& : both positive"; fi
  if [ $a -eq 5 ] || [ $b -eq 10 ]; then echo "|| : one matches"; fi
EOF
  read -p "Press ENTER to run the example..."
  _prompt_action || return
  a=5; b=3
  if ! [ $a -lt $b ]; then cecho GREEN "a) ! : 5 is not less than 3"; fi
  if [ $a -gt 0 ] && [ $b -gt 0 ]; then cecho GREEN "b) && : both positive"; fi
  if [ $a -eq 5 ] || [ $b -eq 10 ]; then cecho GREEN "c) || : one matches"; fi
  _prompt_action || return

  echo
  cecho GREEN "🎉 Completed: Parameter Expansion, Regex, and Test Operators Section"
  cecho BLUE "==================================================================="
}

section_file_search() {
  cecho BLUE "===================================================="
  cecho BOLD "🔍 FILE SEARCHING, FILTERING & TEXT REPLACEMENT DEMOS"
  cecho BLUE "===================================================="
  echo

  TMP_TEST_FILE="./test_search_file.txt"
  cat <<'EOF' > "$TMP_TEST_FILE"
SELinux is enabled and configured.
coronavirus update and COVID stats.
user:x:1000:1000:User:/home/user:/bin/bash
admin:x:1001:1001:Admin:/home/admin:/bin/zsh
guest:x:1002:1002:Guest:/home/guest:/bin/sh
EOF

  cecho CYAN "Sample file created at: $TMP_TEST_FILE"
  echo
  cat "$TMP_TEST_FILE"
  echo
  _prompt_action || return
  
  cecho BLUE "------------------------------"
  cecho BOLD "1. GREP — Search patterns in files"
  cecho BLUE "------------------------------"
  cat <<'EOF'
Example commands:
  a) grep "SELinux" file.txt         → Exact match (case-sensitive)
  b) grep -i "selinux" file.txt      → Case-insensitive match
  c) grep -v "coronavirus" file.txt  → Invert match (exclude lines)
  d) grep -n "user" file.txt         → Show line numbers
  e) grep -E "user|admin" file.txt   → Extended regex OR
  f) grep -A1 "user" file.txt        → Show 1 line After match
  g) grep -B1 "admin" file.txt       → Show 1 line Before match
EOF
  read -p "Press ENTER to run GREP examples..."
  _prompt_action || return
  cecho GREEN "a)"; grep "SELinux" "$TMP_TEST_FILE"
  cecho GREEN "b)"; grep -i "selinux" "$TMP_TEST_FILE"
  cecho GREEN "c)"; grep -v "coronavirus" "$TMP_TEST_FILE"
  cecho GREEN "d)"; grep -n "user" "$TMP_TEST_FILE"
  cecho GREEN "e)"; grep -E "user|admin" "$TMP_TEST_FILE"
  cecho GREEN "f)"; grep -A1 "user" "$TMP_TEST_FILE"
  cecho GREEN "g)"; grep -B1 "admin" "$TMP_TEST_FILE"
  _prompt_action || return

  echo
  cecho BLUE "------------------------------"
  cecho BOLD "2. CUT, AWK, and TR — Extracting Fields"
  cecho BLUE "------------------------------"
  cat <<'EOF'
Example commands:
  a) cut -d: -f1 file.txt         → Extract first field before colon
  b) cut -d: -f1,7 file.txt       → Extract username and shell
  c) awk -F':' '{print $1, $7}'   → Print username and shell using awk
  d) awk '/admin/ {print $1}'     → Print only matching lines for 'admin'
  e) tr '[:lower:]' '[:upper:]'   → Convert to uppercase
EOF
  read -p "Press ENTER to run CUT/AWK/TR examples..."
  _prompt_action || return
  cecho GREEN "a)"; cut -d: -f1 "$TMP_TEST_FILE"
  cecho GREEN "b)"; cut -d: -f1,7 "$TMP_TEST_FILE"
  cecho GREEN "c)"; awk -F':' '{print $1, $7}' "$TMP_TEST_FILE"
  cecho GREEN "d)"; awk '/admin/ {print $1}' "$TMP_TEST_FILE"
  cecho GREEN "e)"; tr '[:lower:]' '[:upper:]' < "$TMP_TEST_FILE"
  _prompt_action || return

  echo
  cecho BLUE "------------------------------"
  cecho BOLD "3. SED — Search & Replace / Insert / Delete"
  cecho BLUE "------------------------------"
  cat <<'EOF'
Example commands:
  a) sed 's/coronavirus/Covid19/' file.txt
     → Replace first occurrence per line
  b) sed 's/Covid19/CoronaVirus/g' file.txt
     → Replace all occurrences per line
  c) sed '/SELinux/d' file.txt
     → Delete lines containing SELinux
  d) sed '2i\Inserted new line before line 2' file.txt
     → Insert a line before line 2
  e) sed '$a\--- End of File ---' file.txt
     → Append line at end of file
  f) sed -i 's/Admin/Administrator/g' file.txt
     → Replace directly inside file
EOF
  read -p "Press ENTER to run SED examples..."
  _prompt_action || return
  cecho GREEN "a)"; sed 's/coronavirus/Covid19/' "$TMP_TEST_FILE"
  cecho GREEN "b)"; sed 's/Covid19/CoronaVirus/g' "$TMP_TEST_FILE"
  cecho GREEN "c)"; sed '/SELinux/d' "$TMP_TEST_FILE"
  cecho GREEN "d)"; sed '2i\Inserted new line before line 2' "$TMP_TEST_FILE"
  cecho GREEN "e)"; sed '$a\--- End of File ---' "$TMP_TEST_FILE"
  cecho GREEN "f) Running -i edit..."
  sed -i 's/Admin/Administrator/g' "$TMP_TEST_FILE"
  cat "$TMP_TEST_FILE"
  _prompt_action || return

  echo
  cecho BLUE "------------------------------"
  cecho BOLD "4. FIND & LOCATE — File Searching"
  cecho BLUE "------------------------------"
  cat <<'EOF'
Example commands:
  a) find . -type f -name "*.txt"
     → Find all text files in current dir
  b) find . -type f -iname "*user*"
     → Case-insensitive search
  c) find /etc -maxdepth 1 -type d
     → List subdirectories (1 level deep)
  d) locate bash
     → Find paths containing 'bash' (needs updatedb)
EOF
  read -p "Press ENTER to run FIND examples..."
  _prompt_action || return
  cecho GREEN "a)"; find . -type f -name "*.txt" | head -5
  cecho GREEN "b)"; find . -type f -iname "*user*" | head -5
  cecho GREEN "c)"; find /etc -maxdepth 1 -type d | head -5
  cecho GREEN "d)"; echo "(locate not available on all systems — demo skipped)"
  _prompt_action || return

  echo
  cecho BLUE "------------------------------"
  cecho BOLD "5. BONUS — Combining Commands"
  cecho BLUE "------------------------------"
  cat <<'EOF'
Examples:
  a) grep "user" file.txt | cut -d: -f1
     → Search and extract usernames
  b) awk -F':' '/bash/ {print $1, $7}'
     → Users using bash shell
  c) grep -i "covid" file.txt | sed 's/covid/Corona/gI'
     → Search case-insensitive and replace inline
EOF
  read -p "Press ENTER to run BONUS examples..."
  _prompt_action || return
  cecho GREEN "a)"; grep "user" "$TMP_TEST_FILE" | cut -d: -f1
  cecho GREEN "b)"; awk -F':' '/bash/ {print $1, $7}' "$TMP_TEST_FILE"
  cecho GREEN "c)"; grep -i "covid" "$TMP_TEST_FILE" | sed 's/covid/Corona/gI'
  _prompt_action || return

  echo
  cecho GREEN "✅ Completed: File Search & Text Manipulation Section"
  cecho BLUE "===================================================="
  return 0
}

section_arithmetic_operations() {
  cecho BLUE "===================================================="
  cecho BOLD "🧮 ARITHMETIC OPERATIONS"
  cecho BLUE "===================================================="
  
  cecho BLUE "------------------------------"
  cecho BOLD "1️⃣ Double Parentheses (( ... ))"
  cecho BLUE "------------------------------"
  cat << 'EOF'
Preferred method for integer arithmetic.
Example:
  (( sum = 5 + 3 ))
  echo $sum
EOF
  read -p "Press ENTER to run..."
  (( sum = 5 + 3 ))
  cecho GREEN "5 + 3 = $sum"
  _prompt_action || return

  cecho BLUE "------------------------------"
  cecho BOLD "2️⃣ 'expr' Command"
  cecho BLUE "------------------------------"
  cat << 'EOF'
Legacy method, still useful in some contexts. careful with spaces!
Example:
  res=$(expr 10 \* 2)
  echo $res
EOF
  read -p "Press ENTER to run..."
  res=$(expr 10 \* 2)
  cecho GREEN "10 * 2 = $res"
  _prompt_action || return
  
  cecho BLUE "------------------------------"
  cecho BOLD "3️⃣ 'bc' for Floating Point"
  cecho BLUE "------------------------------"
  cat << 'EOF'
Bash does not support floating point math natively. Use 'bc'.
Example:
  echo "scale=2; 10 / 3" | bc
EOF
  read -p "Press ENTER to run..."
  if command -v bc >/dev/null 2>&1; then
      val=$(echo "scale=2; 10 / 3" | bc)
      cecho GREEN "10 / 3 = $val"
  else
      cecho YELLOW "'bc' not found. Install it to do float math."
      # Windows Git Bash often has 'bc', but in case it's missing:
      cecho YELLOW "On Windows Git Bash? Try installing it via your installer or use awk:"
      cecho GREEN "awk 'BEGIN {printf \"%.2f\", 10/3}'"
  fi
  _prompt_action || return
}

section_builtin_functions() {
  cecho BLUE "===================================================="
  cecho BOLD "🛠️ SHELL BUILTIN COMMANDS"
  cecho BLUE "===================================================="
  cat << 'EOF'
Builtins work faster as they are part of the shell, not external binaries.
Common builtins: cd, pwd, echo, read, type, help, alias, export, source.
EOF
  _prompt_action || return

  cecho BLUE "------------------------------"
  cecho BOLD "1️⃣ 'type' Command"
  cecho BLUE "------------------------------"
  cat << 'EOF'
Check if a command is a builtin, alias, or file.
Example:
  type cd
  type grep
EOF
  read -p "Press ENTER to run..."
  cecho GREEN "type cd:"; type cd
  cecho GREEN "type grep:"; type grep
  _prompt_action || return

  cecho BLUE "------------------------------"
  cecho BOLD "2️⃣ 'read' Command (User Input)"
  cecho BLUE "------------------------------"
  cat << 'EOF'
Reads a line from standard input.
Example:
  read -p "Enter name: " name
  echo "Hello $name"
EOF
  read -p "Press ENTER to run..."
  read -p "Enter your favorite color: " color
  cecho GREEN "You like $color!"
  _prompt_action || return
}

section_basic_system_commands() {
  cecho BLUE "===================================================="
  cecho BOLD "💻 BASIC LINUX + SYSTEM INFORMATION COMMANDS"
  cecho BLUE "===================================================="
  echo

  cecho BLUE "------------------------------"
  cecho BOLD "1️⃣ Basic Shell Commands"
  cecho BLUE "------------------------------"
  cat <<'EOF'
Examples:
  a) echo "Hello, World!"        → Prints a message
  b) pwd                         → Prints current working directory
  c) date                        → Shows system date and time
  d) whoami                      → Displays current username
  e) hostname                    → Shows system hostname
  f) uname -a                    → Displays full kernel/system info
EOF
  read -p "Press ENTER to run examples..."
  _prompt_action || return
  cecho GREEN "a)"; echo "Hello, World!"
  cecho GREEN "b)"; pwd
  cecho GREEN "c)"; date
  cecho GREEN "d)"; whoami 2>/dev/null || echo "whoami not available"
  cecho GREEN "e)"; hostname 2>/dev/null || echo "hostname not available"
  cecho GREEN "f)"; uname -a 2>/dev/null || echo "uname not available"
  _prompt_action || return

  echo
  cecho BLUE "------------------------------"
  cecho BOLD "2️⃣ File & Directory Commands"
  cecho BLUE "------------------------------"
  cat <<'EOF'
Examples:
  a) ls -l                       → List files with details
  b) mkdir demo_dir              → Create a directory
  c) cd demo_dir                 → Change directory
  d) touch sample.txt            → Create a file
  e) cp sample.txt copy.txt      → Copy file
  f) mv copy.txt moved.txt       → Rename/move file
  g) rm moved.txt                → Remove file
  h) rmdir demo_dir              → Remove directory
EOF
  read -p "Press ENTER to run examples..."
  _prompt_action || return
  cecho GREEN "a)"
  ls -l | head -n 5
  cecho GREEN "b)"
  mkdir -p demo_dir && cecho YELLOW "Directory 'demo_dir' created."
  ls -ld demo_dir
  cecho GREEN "c)"
  cd demo_dir && cecho YELLOW "Changed directory to 'demo_dir'. PWD: $(pwd)"
  cecho GREEN "d)"
  touch sample.txt && cecho YELLOW "Created 'sample.txt'"
  ls -l sample.txt
  cecho GREEN "e)"
  cp sample.txt copy.txt && cecho YELLOW "Copied 'sample.txt' to 'copy.txt'"
  ls -l copy.txt
  cecho GREEN "f)"
  mv copy.txt moved.txt && cecho YELLOW "Renamed 'copy.txt' to 'moved.txt'"
  ls -l moved.txt
  cecho GREEN "g)"
  rm -f moved.txt sample.txt && cecho YELLOW "Removed 'moved.txt' and 'sample.txt'"
  ls -l
  cecho GREEN "h)"
  cd ..
  rmdir demo_dir 2>/dev/null && cecho YELLOW "Removed directory 'demo_dir'" || echo "Could not remove directory"
  echo "Final check (ls -ld demo_dir):"
  ls -ld demo_dir 2>/dev/null || echo "Directory 'demo_dir' successfully removed."
  _prompt_action || return

  echo
  cecho BLUE "------------------------------"
  cecho BOLD "3️⃣ System Information Commands"
  cecho BLUE "------------------------------"
  cat <<'EOF'
Examples:
  a) uptime               → Shows how long system has been running
  b) who                  → Shows logged-in users
  c) top -n 1             → Shows running processes snapshot
  d) ps -ef | head -n 5   → Lists processes
  e) uname -r             → Kernel version
  f) lsb_release -a       → Linux distribution details (if available)
EOF
  read -p "Press ENTER to run examples..."
  _prompt_action || return
  cecho GREEN "a)"
  uptime 2>/dev/null || echo "uptime not available"
  cecho GREEN "b)"
  who 2>/dev/null || echo "who not available"
  cecho GREEN "c)"
  top -n 1 | head -n 10 2>/dev/null || echo "top not available"
  cecho GREEN "d)"
  ps -ef | head -n 5 2>/dev/null || echo "ps not available"
  cecho GREEN "e)"
  uname -r 2>/dev/null || echo "uname not available"
  cecho GREEN "f)"
  if command -v lsb_release >/dev/null 2>&1; then
    lsb_release -a
  else
    echo "lsb_release not available"
  fi
  _prompt_action || return

  echo
  cecho BLUE "------------------------------"
  cecho BOLD "4️⃣ Memory, Disk & CPU Usage"
  cecho BLUE "------------------------------"
  cat <<'EOF'
Examples:
  a) free -m               → Memory usage in MB
  b) df -h                 → Disk space in human-readable format
  c) du -sh *              → Folder sizes in current directory
  d) vmstat 1 3            → System performance summary
  e) lscpu                 → CPU information
EOF
  read -p "Press ENTER to run examples..."
  _prompt_action || return
  cecho GREEN "a)"
  if command -v free >/dev/null 2>&1; then
    free -m
  else
    echo "free not available (Windows Git Bash doesn't have it)"
    echo "Try: systeminfo | findstr /C:\"Memory\""
    systeminfo 2>/dev/null | grep -i "memory" || echo "systeminfo not accessible"
  fi

  cecho GREEN "b)"
  df -h | head -n 8 2>/dev/null || echo "df not available"
  cecho GREEN "c)"
  du -sh * 2>/dev/null | head -n 5 || echo "du not available"
  cecho GREEN "d)"
  vmstat 1 3 2>/dev/null || echo "vmstat not available"
  cecho GREEN "e)"
  lscpu 2>/dev/null || echo "lscpu not available (try: wmic cpu get name)"
  _prompt_action || return

  echo
  cecho BLUE "------------------------------"
  cecho BOLD "5️⃣ Network Information Commands"
  cecho BLUE "------------------------------"
  cat <<'EOF'
Examples:
  a) ip addr show                → Show network interfaces
  b) ping -c 2 8.8.8.8           → Test network connectivity
  c) netstat -tuln OR ss -tuln   → Show listening ports
  d) hostname -I                 → Show local IP addresses
EOF
  read -p "Press ENTER to run examples..."
  _prompt_action || return
  cecho GREEN "a)"
  if command -v ip >/dev/null 2>&1; then
    ip addr show | head -n 10
  else
    echo "ip command not available → Using ipconfig fallback:"
    ipconfig | head -n 10 2>/dev/null || echo "ipconfig not available"
  fi

  cecho GREEN "b)"
  if [[ "$(uname -s)" =~ (CYGWIN|MSYS|MINGW) ]]; then
    ping -n 2 8.8.8.8 2>/dev/null || echo "Ping failed or needs admin rights"
  else
    ping -c 2 8.8.8.8 2>/dev/null || echo "Ping failed or needs admin rights"
  fi
  cecho GREEN "c) (Listening Ports)"
  if command -v ss >/dev/null 2>&1; then
    ss -tuln | head -n 10
  elif command -v netstat >/dev/null 2>&1; then
    netstat -an | head -n 10
  else
    echo "ss/netstat not available"
  fi
  cecho GREEN "d) (Local IP)"
  echo "--- ip a / ifconfig ---"
  if command -v ip >/dev/null 2>&1; then
      ip a | grep -E 'inet|inet6' | head -n 5
  elif command -v ifconfig >/dev/null 2>&1; then
      ifconfig | grep -E 'inet|inet6' | head -n 5
  fi
  echo "--- ipconfig (Windows) ---"
  if command -v ipconfig >/dev/null 2>&1; then
      ipconfig | grep -E "IPv4|IPv6"
  fi
  
  _prompt_action || return

  echo
  
  cecho BLUE "------------------------------"
  cecho BOLD "6️⃣ System Services & Users"
  cecho BLUE "------------------------------"
  cat <<'EOF'
Examples:
  a) id                      → Show current user info
  b) groups                  → Show groups for user
  c) last | head -n 5        → Show login history
  d) systemctl list-units --type=service | head -n 5
                             → Show active services (if systemd)
  e) whoami && echo \$USER    → Show logged-in username
EOF
  read -p "Press ENTER to run examples..."
  _prompt_action || return
  cecho GREEN "a)"
  id 2>/dev/null || echo "id not available"
  cecho GREEN "b)"
  if command -v groups >/dev/null 2>&1; then
      groups
  elif command -v id >/dev/null 2>&1; then
      id -Gn
  else
      echo "groups not available"
  fi
  cecho GREEN "c)"
  last | head -n 5 2>/dev/null || echo "last command not available on this system"
  cecho GREEN "d)"
  if command -v systemctl >/dev/null 2>&1; then
    systemctl list-units --type=service | head -n 5
  else
    echo "systemctl not available"
    echo "Running 'tasklist' (Windows) instead:"
    tasklist | head -n 5 2>/dev/null || echo "tasklist not accessible"
  fi

  cecho GREEN "e)"
  whoami 2>/dev/null || echo "whoami not available"
  echo "${USER:-$(whoami 2>/dev/null || echo 'USER variable not set')}"
  # Prompt to continue to next level (skips remaining levels in section if 'q')
  _prompt_action "Press ENTER to continue to next level, 'q' to skip remaining levels, 'Q' to quit: " || return 1
  

  echo
  cecho GREEN "✅ Completed: Basic Linux + System Commands Section"
  cecho BLUE "===================================================="
  return 0
}

section_bandit_levels() {
  # Initialize variables for passwords
  CURRENT_PASS="bandit0"
  export BANDIT1_PASS=""
  export BANDIT2_PASS=""
  export BANDIT3_PASS=""
  export BANDIT4_PASS=""
  export BANDIT5_PASS=""
  export BANDIT6_PASS=""
  export BANDIT7_PASS=""
  export BANDIT8_PASS=""
  export BANDIT9_PASS=""
  export BANDIT10_PASS=""
  export BANDIT11_PASS=""
  export BANDIT12_PASS=""
  export BANDIT13_PASS=""
  export BANDIT14_PASS=""
  export BANDIT15_PASS=""
  export BANDIT16_PASS=""
  export BANDIT17_PASS=""
  export BANDIT18_PASS=""
  export BANDIT19_PASS=""
  export BANDIT20_PASS=""
  export BANDIT21_PASS=""
  export BANDIT22_PASS=""
  export BANDIT23_PASS=""
  export BANDIT24_PASS=""
  export BANDIT25_PASS=""
  export BANDIT26_PASS=""
  export BANDIT27_PASS=""
  export BANDIT28_PASS=""
  export BANDIT29_PASS=""
  export BANDIT30_PASS=""
  export BANDIT31_PASS=""
  export BANDIT32_PASS=""
  export BANDIT33_PASS=""

  cecho PURPLE "🚀 Starting OverTheWire Bandit Levels Guide"
  cecho WHITE "This guide will walk you through levels 0-33 interactively."
  cecho WHITE "For each level:"
  cecho WHITE "  - Read the task description."
  cecho WHITE "  - See the example commands (you can copy-paste them)."
  cecho WHITE "  - View simulated output."
  cecho WHITE "  - Run it yourself in a terminal (SSH to the server)."
  cecho WHITE "  - Enter the password you find to save it for the next level."
  cecho YELLOW "Note: Passwords change periodically; simulated outputs use recent known values."
  cecho CYAN "Host: bandit.labs.overthewire.org -p 2220"
  echo

  # Level 0
  cecho BLUE "--------------------"
  cecho BOLD "0️⃣ Bandit Level 0"
  cecho BLUE "--------------------"
  cecho WHITE "Task: Login to the server and find the password for level 1 in a file called 'readme' in the home directory."
  cat << 'EOF'
# SSH login (password: bandit0)
ssh bandit0@bandit.labs.overthewire.org -p 2220

# Once logged in:
cat readme
EOF
  echo
  # Prompt to continue to next level (skips remaining levels in section if 'q')
  _prompt_action "Press ENTER to continue to next level, 'q' to skip remaining levels, 'Q' to quit: " || return 1

  cecho GREEN "Simulated shell session:"
  cecho GREEN '$ ssh bandit0@bandit.labs.overthewire.org -p 2220'
  cecho GREEN "bandit0@bandit.labs.overthewire.org's password: [enter bandit0]"
  cecho GREEN "bandit0@bandit:~$ cat readme"
  cecho GREEN "boJ9jbbUNNfktd78OOpsqOltutMc3MY1"
  cecho GREEN "bandit0@bandit:~$ exit"
  echo
  cecho GREEN "Password found: boJ9jbbUNNfktd78OOpsqOltutMc3MY1"
  read -p "Run this yourself? When done, enter the password you found (or press ENTER to skip saving): " input
  if [[ -n "$input" ]]; then
    export BANDIT1_PASS="$input"
    cecho GREEN "Saved as BANDIT1_PASS."
  fi

  # Prompt to continue to next level (skips remaining levels in section if 'q')
  _prompt_action "Press ENTER to continue to next level, 'q' to skip remaining levels, 'Q' to quit: " || return 1
  
  # Level 1
  cecho BLUE "--------------------"
  cecho BOLD "1️⃣ Bandit Level 1"
  cecho BLUE "--------------------"
  cecho WHITE "Task: The password for the next level is stored in a file called '-'."
  cat << 'EOF'
# SSH login (use BANDIT1_PASS or prompt)
ssh bandit1@bandit.labs.overthewire.org -p 2220

# Once logged in:
cat ./-    # Note the dot-slash and handling of leading dash
EOF
  echo
  read -p "Press ENTER to see simulated output..."
  _prompt_action || return 1
  cecho GREEN "Simulated shell session:"
  cecho GREEN '$ ssh bandit1@bandit.labs.overthewire.org -p 2220'
  cecho GREEN "bandit1@bandit:~$ cat ./-"
  cecho GREEN "CV1DtqXWVFXTvM2F0k09SHz0YwRINYA9"
  cecho GREEN "bandit1@bandit:~$ ls"
  cecho GREEN "-"
  cecho GREEN "bandit1@bandit:~$ exit"
  echo
  cecho GREEN "Password found: CV1DtqXWVFXTvM2F0k09SHz0YwRINYA9"
  read -p "Run this yourself? When done, enter the password you found (or press ENTER to skip saving): " input
  if [[ -n "$input" ]]; then
    export BANDIT2_PASS="$input"
    cecho GREEN "Saved as BANDIT2_PASS."
  fi
  # Prompt to continue to next level (skips remaining levels in section if 'q')
  _prompt_action "Press ENTER to continue to next level, 'q' to skip remaining levels, 'Q' to quit: " || return 1
  

  # Level 2
  cecho BLUE "--------------------"
  cecho BOLD "2️⃣ Bandit Level 2"
  cecho BLUE "--------------------"
  cecho WHITE "Task: The password for the next level is stored in a file called 'spaces in this filename'."
  cat << 'EOF'
# SSH login
ssh bandit2@bandit.labs.overthewire.org -p 2220

# Once logged in:
cat "./spaces in this filename"    # Quote the filename with spaces
# Or: cat "spaces in this filename"
EOF
  echo
  echo
  read -p "Press ENTER to see simulated output..."
  _prompt_action || return 1
  cecho GREEN "Simulated shell session:"
  cecho GREEN "bandit2@bandit:~$ cat './spaces in this filename'"
  cecho GREEN "UmHadQclWmgdLOKQ3YNgjWxGoRMb5luK"
  cecho GREEN "bandit2@bandit:~$ ls"
  cecho GREEN "spaces in this filename"
  cecho GREEN "bandit2@bandit:~$ exit"
  echo
  cecho GREEN "Password found: UmHadQclWmgdLOKQ3YNgjWxGoRMb5luK"
  read -p "Run this yourself? When done, enter the password you found (or press ENTER to skip saving): " input
  if [[ -n "$input" ]]; then
    export BANDIT3_PASS="$input"
    cecho GREEN "Saved as BANDIT3_PASS."
  fi

  # Prompt to continue to next level (skips remaining levels in section if 'q')
  _prompt_action "Press ENTER to continue to next level, 'q' to skip remaining levels, 'Q' to quit: " || return 1
  
# Level 3
  cecho BLUE "--------------------"
  cecho BOLD "3️⃣ Bandit Level 3"
  cecho BLUE "--------------------"
  cecho WHITE "Task: The password for the next level is stored in a hidden file in the 'inhere' directory."
  cat << 'EOF'
# SSH login
ssh bandit3@bandit.labs.overthewire.org -p 2220

# Once logged in:
ls
cd inhere/
ls -la    # List all files, including hidden
cat .hidden    # Or whatever the hidden file is named; use ls -la to find it
EOF
  echo
  read -p "Press ENTER to see simulated output..."
  _prompt_action || return
  cecho GREEN "Simulated shell session:"
  cecho GREEN "bandit3@bandit:~$ ls"
  cecho GREEN "inhere"
  cecho GREEN "bandit3@bandit:~$ cd inhere/"
  cecho GREEN "bandit3@bandit:~/inhere$ ls -la"
  cecho GREEN "total 12"
  cecho GREEN "drwxr-xr-x 2 root root 4096 ... .."
  cecho GREEN "-rw-r--r-- 1 bandit4 bandit3 33 ... .hidden"
  cecho GREEN "bandit3@bandit:~/inhere$ cat .hidden"
  cecho GREEN "pIwrPrtPN36QITSp3EQaw936yaFoFgAB"
  cecho GREEN "bandit3@bandit:~/inhere$ exit"
  echo
  cecho GREEN "Password found: pIwrPrtPN36QITSp3EQaw936yaFoFgAB"
  read -p "Run this yourself? When done, enter the password you found (or press ENTER to skip saving): " input
  if [[ -n "$input" ]]; then
    export BANDIT4_PASS="$input"
    cecho GREEN "Saved as BANDIT4_PASS."
  fi

  # Prompt to continue to next level (skips remaining levels in section if 'q')
  _prompt_action "Press ENTER to continue to next level, 'q' to skip remaining levels, 'Q' to quit: " || return 1
  
  # Level 4
  cecho BLUE "--------------------"
  cecho BOLD "4️⃣ Bandit Level 4"
  cecho BLUE "--------------------"
  cecho WHITE "Task: The password for the next level is stored in the only human-readable file in the 'inhere' directory."
  cat << 'EOF'
# SSH login
ssh bandit4@bandit.labs.overthewire.org -p 2220

# Once logged in:
ls
cd inhere/
ls -la
file *    # Check file types
cat [human-readable-file]    # e.g., cat maybehere07/.file2
EOF
  echo
  read -p "Press ENTER to see simulated output..."
  _prompt_action || return
  cecho GREEN "Simulated shell session:"
  cecho GREEN "bandit4@bandit:~$ cd inhere/"
  cecho GREEN "bandit4@bandit:~/inhere$ file *"
  cecho GREEN "./-file07: ASCII text"
  cecho GREEN "./others: data"
  cecho GREEN "bandit4@bandit:~/inhere$ cat ./-file07"
  cecho GREEN "koReBOKuIDDepwhWk7jZC0RTdopnAYKh"
  cecho GREEN "bandit4@bandit:~/inhere$ exit"
  echo
  cecho GREEN "Password found: koReBOKuIDDepwhWk7jZC0RTdopnAYKh"
  read -p "Run this yourself? When done, enter the password you found (or press ENTER to skip saving): " input
  if [[ -n "$input" ]]; then
    export BANDIT5_PASS="$input"
    cecho GREEN "Saved as BANDIT5_PASS."
  fi

  # Prompt to continue to next level (skips remaining levels in section if 'q')
  _prompt_action "Press ENTER to continue to next level, 'q' to skip remaining levels, 'Q' to quit: " || return 1
  

  # Level 5
  cecho BLUE "--------------------"
  cecho BOLD "5️⃣ Bandit Level 5"
  cecho BLUE "--------------------"
  cecho WHITE "Task: The password for the next level is stored in a file somewhere under the 'inhere' directory with these properties: human-readable, 1033 bytes, not executable."
  cat << 'EOF'
# SSH login
ssh bandit5@bandit.labs.overthewire.org -p 2220

# Once logged in:
cd inhere/
find . -type f -size 1033c ! -executable -exec file {} \; | grep ASCII
cat [matching-file]    # e.g., cat ./maybehere07/.file2
EOF
  echo
  read -p "Press ENTER to see simulated output..."
  _prompt_action || return
  cecho GREEN "Simulated shell session:"
  cecho GREEN "bandit5@bandit:~/inhere$ find . -type f -size 1033c ! -executable -exec file {} \; | grep ASCII"
  cecho GREEN "./maybehere07/.file2: ASCII text"
  cecho GREEN "bandit5@bandit:~/inhere$ cat ./maybehere07/.file2"
  cecho GREEN "DXjZPULLxYr17uwoI01bNLQbtFemEgo7"
  cecho GREEN "bandit5@bandit:~/inhere$ exit"
  echo
  cecho GREEN "Password found: DXjZPULLxYr17uwoI01bNLQbtFemEgo7"
  read -p "Run this yourself? When done, enter the password you found (or press ENTER to skip saving): " input
  if [[ -n "$input" ]]; then
    export BANDIT6_PASS="$input"
    cecho GREEN "Saved as BANDIT6_PASS."
  fi

  # Prompt to continue to next level (skips remaining levels in section if 'q')
  _prompt_action "Press ENTER to continue to next level, 'q' to skip remaining levels, 'Q' to quit: " || return 1
  
  # Level 6
  cecho BLUE "--------------------"
  cecho BOLD "6️⃣ Bandit Level 6"
  cecho BLUE "--------------------"
  cecho WHITE "Task: Find a file owned by user bandit7, group bandit6, 33 bytes in size."
  cat << 'EOF'
# SSH login
ssh bandit6@bandit.labs.overthewire.org -p 2220

# Once logged in:
find / -type f -user bandit7 -group bandit6 -size 33c 2>/dev/null
cat [found-file]    # e.g., cat /var/lib/dpkg/info/bandit7.password
EOF
  echo
  read -p "Press ENTER to see simulated output..."
  _prompt_action || return
  cecho GREEN "Simulated shell session:"
  cecho GREEN "bandit6@bandit:~$ find / -type f -user bandit7 -group bandit6 -size 33c 2>/dev/null"
  cecho GREEN "/var/lib/dpkg/info/bandit7.password"
  cecho GREEN "bandit6@bandit:~$ cat /var/lib/dpkg/info/bandit7.password"
  cecho GREEN "HKBPTKQnIay4Fw76bEy8PVxKEDQRKTzs"
  cecho GREEN "bandit6@bandit:~$ exit"
  echo
  cecho GREEN "Password found: HKBPTKQnIay4Fw76bEy8PVxKEDQRKTzs"
  read -p "Run this yourself? When done, enter the password you found (or press ENTER to skip saving): " input
  if [[ -n "$input" ]]; then
    export BANDIT7_PASS="$input"
    cecho GREEN "Saved as BANDIT7_PASS."
  fi

  # Prompt to continue to next level (skips remaining levels in section if 'q')
  _prompt_action "Press ENTER to continue to next level, 'q' to skip remaining levels, 'Q' to quit: " || return 1
  

  # Level 7
  cecho BLUE "--------------------"
  cecho BOLD "7️⃣ Bandit Level 7"
  cecho BLUE "--------------------"
  cecho WHITE "Task: The password for level 8 is in data.txt next to the word 'millionth'."
  cat << 'EOF'
# SSH login
ssh bandit7@bandit.labs.overthewire.org -p 2220

# Once logged in:
grep "millionth" data.txt
EOF
  echo
  read -p "Press ENTER to see simulated output..."
  _prompt_action || return
  cecho GREEN "Simulated shell session:"
  cecho GREEN "bandit7@bandit:~$ grep millionth data.txt"
  cecho GREEN "  Millionth    cvX2JJa4CFALtqS87jk27qwqGhBM9plV"
  cecho GREEN "bandit7@bandit:~$ exit"
  echo
  cecho GREEN "Password found: cvX2JJa4CFALtqS87jk27qwqGhBM9plV"
  read -p "Run this yourself? When done, enter the password you found (or press ENTER to skip saving): " input
  if [[ -n "$input" ]]; then
    export BANDIT8_PASS="$input"
    cecho GREEN "Saved as BANDIT8_PASS."
  fi

  # Prompt to continue to next level (skips remaining levels in section if 'q')
  _prompt_action "Press ENTER to continue to next level, 'q' to skip remaining levels, 'Q' to quit: " || return 1

  # Level 8
  cecho BLUE "--------------------"
  cecho BOLD "8️⃣ Bandit Level 8"
  cecho BLUE "--------------------"
  cecho WHITE "Task: The password for level 9 is the only line in data.txt that occurs only once."
  cat << 'EOF'
# SSH login
ssh bandit8@bandit.labs.overthewire.org -p 2220

# Once logged in:
sort data.txt | uniq -u
EOF
  echo
  read -p "Press ENTER to see simulated output..."
  _prompt_action || return
  cecho GREEN "Simulated shell session:"
  cecho GREEN "bandit8@bandit:~$ sort data.txt | uniq -u"
  cecho GREEN "UsvVyFSfZZWbi6wgC7dAFyFuR6jQQUhR"
  cecho GREEN "bandit8@bandit:~$ exit"
  echo
  cecho GREEN "Password found: UsvVyFSfZZWbi6wgC7dAFyFuR6jQQUhR"
  read -p "Run this yourself? When done, enter the password you found (or press ENTER to skip saving): " input
  if [[ -n "$input" ]]; then
    export BANDIT9_PASS="$input"
    cecho GREEN "Saved as BANDIT9_PASS."
  fi

  # Prompt to continue to next level (skips remaining levels in section if 'q')
  _prompt_action "Press ENTER to continue to next level, 'q' to skip remaining levels, 'Q' to quit: " || return 1
  
  # Level 9
  cecho BLUE "--------------------"
  cecho BOLD "9️⃣ Bandit Level 9"
  cecho BLUE "--------------------"
  cecho WHITE "Task: The password for level 10 is in data.txt, one of the few human-readable strings preceded by several '=' characters."
  cat << 'EOF'
# SSH login
ssh bandit9@bandit.labs.overthewire.org -p 2220

# Once logged in:
strings data.txt | grep ====
EOF
  echo
  read -p "Press ENTER to see simulated output..."
  _prompt_action || return
  cecho GREEN "Simulated shell session:"
  cecho GREEN "bandit9@bandit:~$ strings data.txt | grep ===="
  cecho GREEN "========== the password is truKLdjsbJ5g7yyJ2X2R0o3a5HQJFuLk =========="
  cecho GREEN "bandit9@bandit:~$ exit"
  echo
  cecho GREEN "Password found: truKLdjsbJ5g7yyJ2X2R0o3a5HQJFuLk"
  read -p "Run this yourself? When done, enter the password you found (or press ENTER to skip saving): " input
  if [[ -n "$input" ]]; then
    export BANDIT10_PASS="$input"
    cecho GREEN "Saved as BANDIT10_PASS."
  fi

  # Prompt to continue to next level (skips remaining levels in section if 'q')
  _prompt_action "Press ENTER to continue to next level, 'q' to skip remaining levels, 'Q' to quit: " || return 1
  
  # Level 10
  cecho BLUE "--------------------"
  cecho BOLD "🔟 Bandit Level 10"
  cecho BLUE "--------------------"
  cecho WHITE "Task: The password for level 11 is in data.txt, which contains base64 encoded data."
  cat << 'EOF'
# SSH login
ssh bandit10@bandit.labs.overthewire.org -p 2220

# Once logged in:
base64 -d data.txt
EOF
  echo
  read -p "Press ENTER to see simulated output..."
  _prompt_action || return
  cecho GREEN "Simulated shell session:"
  cecho GREEN "bandit10@bandit:~$ base64 -d data.txt"
  cecho GREEN "IFukwKGsFW8MOq3IRFqrxE1hxTNEbUPR"
  cecho GREEN "bandit10@bandit:~$ exit"
  echo
  cecho GREEN "Password found: IFukwKGsFW8MOq3IRFqrxE1hxTNEbUPR"
  read -p "Run this yourself? When done, enter the password you found (or press ENTER to skip saving): " input
  if [[ -n "$input" ]]; then
    export BANDIT11_PASS="$input"
    cecho GREEN "Saved as BANDIT11_PASS."
  fi

  # Prompt to continue to next level (skips remaining levels in section if 'q')
  _prompt_action "Press ENTER to continue to next level, 'q' to skip remaining levels, 'Q' to quit: " || return 1
  
  # Level 11
  cecho BLUE "--------------------"
  cecho BOLD "1️⃣1️⃣ Bandit Level 11"
  cecho BLUE "--------------------"
  cecho WHITE "Task: The password for level 12 is in data.txt, rotated by 13 positions (ROT13)."
  cat << 'EOF'
# SSH login
ssh bandit11@bandit.labs.overthewire.org -p 2220

# Once logged in:
tr 'A-Za-z' 'N-ZA-Mn-za-m' data.txt
EOF
  echo
  read -p "Press ENTER to see simulated output..."
  _prompt_action || return
  cecho GREEN "Simulated shell session:"
  cecho GREEN "bandit11@bandit:~$ tr 'A-Za-z' 'N-ZA-Mn-za-m' data.txt"
  cecho GREEN "5Te8Y4drgCRfCx8ugdwuEX8KFC6k2EUu"
  cecho GREEN "bandit11@bandit:~$ exit"
  echo
  cecho GREEN "Password found: 5Te8Y4drgCRfCx8ugdwuEX8KFC6k2EUu"
  read -p "Run this yourself? When done, enter the password you found (or press ENTER to skip saving): " input
  if [[ -n "$input" ]]; then
    export BANDIT12_PASS="$input"
    cecho GREEN "Saved as BANDIT12_PASS."
  fi

  # Prompt to continue to next level (skips remaining levels in section if 'q')
  _prompt_action "Press ENTER to continue to next level, 'q' to skip remaining levels, 'Q' to quit: " || return 1
  
  # Level 12
  cecho BLUE "--------------------"
  cecho BOLD "1️⃣2️⃣ Bandit Level 12"
  cecho BLUE "--------------------"
  cecho WHITE "Task: The password for level 13 is in data.txt, a hexdump of repeatedly compressed data. Decompress step by step in /tmp."
  cat << 'EOF'
# SSH login
ssh bandit12@bandit.labs.overthewire.org -p 2220

# Once logged in (multi-step):
mkdir ./myfolder
cp data.txt ./myfolder
cd ./myfolder
xxd -r data.txt > data1
mv data1 data2.gz
gunzip data2.gz
mv data2 data3.bz2
bunzip2 data3.bz2
# Continue similarly: gzip, tar, bzip2, etc., until you get the password file
cat final-file.txt
EOF
  echo
  read -p "Press ENTER to see simulated output..."
  _prompt_action || return
  cecho GREEN "Simulated shell session (abbreviated):"
  cecho GREEN "bandit12@bandit:./myfolder$ # After all decomp steps..."
  cecho GREEN "bandit12@bandit:./myfolder$ cat data9"
  cecho GREEN "8ZjyCRiBWFYkneahHwxCv3wb2a1ORpYL"
  cecho GREEN "bandit12@bandit:~$ exit"
  cecho GREEN "Note: Full steps involve multiple gzip, bzip2, tar extractions."
  echo
  cecho GREEN "Password found: 8ZjyCRiBWFYkneahHwxCv3wb2a1ORpYL"
  read -p "Run this yourself? When done, enter the password you found (or press ENTER to skip saving): " input
  if [[ -n "$input" ]]; then
    export BANDIT13_PASS="$input"
    cecho GREEN "Saved as BANDIT13_PASS."
  fi

  # Prompt to continue to next level (skips remaining levels in section if 'q')
  _prompt_action "Press ENTER to continue to next level, 'q' to skip remaining levels, 'Q' to quit: " || return 1
  
  # Level 13
  cecho BLUE "--------------------"
  cecho BOLD "1️⃣3️⃣ Bandit Level 13"
  cecho BLUE "--------------------"
  cecho WHITE "Task: For level 14, you get a private SSH key (sshkey.private) instead of a password. Use it to login to bandit14@localhost."
  cat << 'EOF'
# SSH login to 13 (use previous pass)
ssh bandit13@bandit.labs.overthewire.org -p 2220

# Once logged in:
ls    # See sshkey.private
ssh -i sshkey.private bandit14@localhost
EOF
  echo
  read -p "Press ENTER to see simulated output..."
  _prompt_action || return
  cecho GREEN "Simulated shell session:"
  cecho GREEN "bandit13@bandit:~$ ssh -i sshkey.private bandit14@localhost"
  cecho GREEN "bandit14@bandit:~$ cat /etc/bandit_pass/bandit14  # For next level"
  cecho GREEN "BfMYroe26WYalil77FoDi9qh59eK5xNr"
  cecho GREEN "bandit14@bandit:~$ exit"
  echo
  cecho GREEN "Password found for level 15: BfMYroe26WYalil77FoDi9qh59eK5xNr (no export for key; save password)"
  read -p "Run this yourself? When done, enter the password you found for level 15 (or press ENTER to skip saving): " input
  if [[ -n "$input" ]]; then
    export BANDIT15_PASS="$input"
    cecho GREEN "Saved as BANDIT15_PASS."
  fi

  # Prompt to continue to next level (skips remaining levels in section if 'q')
  _prompt_action "Press ENTER to continue to next level, 'q' to skip remaining levels, 'Q' to quit: " || return 1
  
  # Level 14
  cecho BLUE "--------------------"
  cecho BOLD "1️⃣4️⃣ Bandit Level 14"
  cecho BLUE "--------------------"
  cecho WHITE "Task: The password for level 15 is in /etc/bandit_pass/bandit14. Submit it to port 30000 on localhost using telnet."
  cat << 'EOF'
# You are already logged in as bandit14 from previous (using key)

# In the bandit14 session:
cat /etc/bandit_pass/bandit14

# New terminal/session:
telnet localhost 30000
# Paste the password when prompted, then type 'quit' or escape
EOF
  echo
  read -p "Press ENTER to see simulated output..."
  _prompt_action || return
  cecho GREEN "Simulated shell session:"
  cecho GREEN "bandit14@bandit:~$ cat /etc/bandit_pass/bandit14"
  cecho GREEN "4wcYUJFw0k0XLShlDzztnTBHiqxU3b3e  # Example current pass"
  echo
  cecho GREEN '$ telnet localhost 30000'
  cecho GREEN "Trying 127.0.0.1..."
  cecho GREEN "Connected to localhost."
  cecho GREEN "Please enter the password for bandit15: [paste 4wcYUJFw0k0XLShlDzztnTBHiqxU3b3e]"
  cecho GREEN "Protocol: ssl"
  cecho GREEN "bfMYroe26WYalil77FoDi9qh59eK5xNr"  # Response password
  cecho GREEN "Connection closed by foreign host."
  echo
  cecho GREEN "Password found: BfMYroe26WYalil77FoDi9qh59eK5xNr"
  read -p "Run this yourself? When done, enter the password you found (or press ENTER to skip saving): " input
  if [[ -n "$input" ]]; then
    export BANDIT16_PASS="$input"
    cecho GREEN "Saved as BANDIT16_PASS."
  fi

  # Prompt to continue to next level (skips remaining levels in section if 'q')
  _prompt_action "Press ENTER to continue to next level, 'q' to skip remaining levels, 'Q' to quit: " || return 1
  
  # Level 15
  cecho BLUE "--------------------"
  cecho BOLD "1️⃣5️⃣ Bandit Level 15"
  cecho BLUE "--------------------"
  cecho WHITE "Task: Submit the level 15 password to port 30001 on localhost using SSL (openssl)."
  cat << 'EOF'
# SSH login to 15 (use previous pass)
ssh bandit15@bandit.labs.overthewire.org -p 2220

# In the session:
# New terminal:
openssl s_client -connect localhost:30001 -quiet -ign_eof
# Paste the password when prompted
EOF
  echo
  read -p "Press ENTER to see simulated output..."
  _prompt_action || return
  cecho GREEN "Simulated shell session:"
  cecho GREEN '$ openssl s_client -connect localhost:30001 -ign_eof'
  cecho GREEN "CONNECTED(00000003)"
  cecho GREEN "Please enter the password for bandit16: [paste BfMYroe26WYalil77FoDi9qh59eK5xNr]"
  cecho GREEN "Protocol: ssl"
  cecho GREEN "cluFn7wTiGryunymYOu4RcffSxQluehd"
  echo
  cecho GREEN "Password found: cluFn7wTiGryunymYOu4RcffSxQluehd"
  read -p "Run this yourself? When done, enter the password you found (or press ENTER to skip saving): " input
  if [[ -n "$input" ]]; then
    export BANDIT17_PASS="$input"
    cecho GREEN "Saved as BANDIT17_PASS."
  fi

  # Prompt to continue to next level (skips remaining levels in section if 'q')
  _prompt_action "Press ENTER to continue to next level, 'q' to skip remaining levels, 'Q' to quit: " || return 1
  
  # Level 16
  cecho BLUE "--------------------"
  cecho BOLD "1️⃣6️⃣ Bandit Level 16"
  cecho BLUE "--------------------"
  cecho WHITE "Task: Congratulations! You've completed levels 0-16. The password for level 17 is found similarly, but this guide stops here."
  cecho WHITE "To proceed to level 17, login with the last password and follow the official hints."
  cat << 'EOF'
# SSH login to 16
ssh bandit16@bandit.labs.overthewire.org -p 2220

# Explore further...
EOF
  echo
  read -p "Press ENTER to see final note..."
  _prompt_action || return
  cecho GREEN "🎉 All levels guided! Check your exported variables with 'echo $BANDIT17_PASS'."
  cecho GREEN "Remember: These teach basic Linux commands, file handling, and tools like grep, find, tr, etc."
  cecho GREEN "Practice on your own machine too!"

  # Prompt to continue to next level (skips remaining levels in section if 'q')
  _prompt_action "Press ENTER to continue to next level, 'q' to skip remaining levels, 'Q' to quit: " || return 1
  

  # Level 17
  cecho BLUE "--------------------"
  cecho BOLD "1️⃣7️⃣ Bandit Level 17"
  cecho BLUE "--------------------"
  cecho WHITE "Task: The password for level 18 is an RSA private key. Find the open SSL port between 31000-32000, connect using openssl s_client, and submit the level 16 password to retrieve the key."
  cat << 'EOF'
# SSH login to level 16
ssh bandit16@bandit.labs.overthewire.org -p 2220

# Once logged in, scan for the port:
for i in {31000..32000}; do
  echo exit | openssl s_client -quiet -connect localhost:$i -servername localhost 2>/dev/null | grep -q "Protocol : TLSv1.2"
  if [ $? -eq 0 ]; then
    echo "Open port: $i"
  fi
done

# Connect to the found port (e.g., 31046) and paste the level 16 password when prompted
(echo "YOUR_LEVEL16_PASSWORD"; echo; sleep 1; cat) | openssl s_client -quiet -connect localhost:31046 -servername localhost
# Save the output (RSA private key) to a local file: bandit17.key
EOF
  echo
  read -p "Press ENTER to see simulated output..."
  _prompt_action || return
  cecho GREEN "Simulated shell session:"
  cecho GREEN "bandit16@bandit:~$ for i in {31000..32000}; do echo exit | openssl s_client -quiet -connect localhost:\$i -servername localhost 2>/dev/null | grep -q \"Protocol : TLSv1.2\"; if [ \$? -eq 0 ]; then echo \"Open port: \$i\"; fi; done"
  cecho GREEN "Open port: 31046"
  cecho GREEN "bandit16@bandit:~$ (echo \"cluFn7wTiGryunymYOu4RcffSxQluehd\"; echo; sleep 1; cat) | openssl s_client -quiet -connect localhost:31046 -servername localhost"
  cecho GREEN "-----BEGIN RSA PRIVATE KEY-----"
  cecho GREEN "MIIEogIBAAKCAQEAvmOkuifmXAbXSRGA7l4..."
  cecho GREEN "[Full key output - save to bandit17.key locally]"
  cecho GREEN "-----END RSA PRIVATE KEY-----"
  cecho GREEN "bandit16@bandit:~$ exit"
  echo
  cecho GREEN "No password; save the RSA private key to 'bandit17.key' on your local machine (chmod 600 bandit17.key)"

  # Prompt to continue to next level (skips remaining levels in section if 'q')
  _prompt_action "Press ENTER to continue to next level, 'q' to skip remaining levels, 'Q' to quit: " || return 1
  
  # Level 18
  cecho BLUE "--------------------"
  cecho BOLD "1️⃣8️⃣ Bandit Level 18"
  cecho BLUE "--------------------"
  cecho WHITE "Task: Login using the RSA private key from level 17. The password is in passwords.new, the only line changed from passwords.old."
  cat << 'EOF'
# Local command (use the saved key):
ssh -i bandit17.key bandit17@bandit.labs.overthewire.org -p 2220

# Once logged in:
diff passwords.old passwords.new
# The added line (+) is the password
EOF
  echo
  read -p "Press ENTER to see simulated output..."
  _prompt_action || return
  cecho GREEN "Simulated shell session:"
  cecho GREEN '$ ssh -i bandit17.key bandit17@bandit.labs.overthewire.org -p 2220'
  cecho GREEN "bandit17@bandit:~$ diff passwords.old passwords.new"
  cecho GREEN "42c42"
  cecho GREEN "< NNNNNNNNNNNNNNNNNNNNNNNNNNNN"
  cecho GREEN "---"
  cecho GREEN "> x2gLTTjFwMOhQ8oWNbMN362QKxfRqGlO"
  cecho GREEN "bandit17@bandit:~$ exit"
  echo
  cecho GREEN "Password found: x2gLTTjFwMOhQ8oWNbMN362QKxfRqGlO"
  read -p "Run this yourself? When done, enter the password you found (or press ENTER to skip saving): " input
  if [[ -n "$input" ]]; then
    export BANDIT18_PASS="$input"
    cecho GREEN "Saved as BANDIT18_PASS."
  fi

  # Prompt to continue to next level (skips remaining levels in section if 'q')
  _prompt_action "Press ENTER to continue to next level, 'q' to skip remaining levels, 'Q' to quit: " || return 1
  
  # Level 19
  cecho BLUE "--------------------"
  cecho BOLD "1️⃣9️⃣ Bandit Level 19"
  cecho BLUE "--------------------"
  cecho WHITE "Task: The shell exits immediately, so use SSH command execution to cat the readme file in bandit18's home."
  cat << 'EOF'
# From local machine:
ssh bandit18@bandit.labs.overthewire.org -p 2220 'cat /home/bandit18/README'
EOF
  echo
  read -p "Press ENTER to see simulated output..."
  _prompt_action || return
  cecho GREEN "Simulated shell session:"
  cecho GREEN '$ ssh bandit18@bandit.labs.overthewire.org -p 2220 "cat /home/bandit18/README"'
  cecho GREEN "The password to the next level is: cGWpMaKXVwDUNgPAVJbWYuGHVn9zl3j8"
  echo
  cecho GREEN "Password found: cGWpMaKXVwDUNgPAVJbWYuGHVn9zl3j8"
  read -p "Run this yourself? When done, enter the password you found (or press ENTER to skip saving): " input
  if [[ -n "$input" ]]; then
    export BANDIT19_PASS="$input"
    cecho GREEN "Saved as BANDIT19_PASS."
  fi

  # Prompt to continue to next level (skips remaining levels in section if 'q')
  _prompt_action "Press ENTER to continue to next level, 'q' to skip remaining levels, 'Q' to quit: " || return 1
  
  # Level 20
  cecho BLUE "--------------------"
  cecho BOLD "2️⃣0️⃣ Bandit Level 20"
  cecho BLUE "--------------------"
  cecho WHITE "Task: Use the setuid binary bandit20-do to run commands as bandit20 and cat the password file."
  cat << 'EOF'
# SSH login
ssh bandit19@bandit.labs.overthewire.org -p 2220

# Once logged in:
./bandit20-do cat /etc/bandit_pass/bandit20
EOF
  echo
  read -p "Press ENTER to see simulated output..."
  _prompt_action || return
  cecho GREEN "Simulated shell session:"
  cecho GREEN "bandit19@bandit:~$ ./bandit20-do cat /etc/bandit_pass/bandit20"
  cecho GREEN "0qXahG8ZjOVMN9Ghs7iOWsCfZyXOUbYO"
  cecho GREEN "bandit19@bandit:~$ exit"
  echo
  cecho GREEN "Password found: 0qXahG8ZjOVMN9Ghs7iOWsCfZyXOUbYO"
  read -p "Run this yourself? When done, enter the password you found (or press ENTER to skip saving): " input
  if [[ -n "$input" ]]; then
    export BANDIT20_PASS="$input"
    cecho GREEN "Saved as BANDIT20_PASS."
  fi

  # Prompt to continue to next level (skips remaining levels in section if 'q')
  _prompt_action "Press ENTER to continue to next level, 'q' to skip remaining levels, 'Q' to quit: " || return 1
  
  # Level 21
  cecho BLUE "--------------------"
  cecho BOLD "2️⃣1️⃣ Bandit Level 21"
  cecho BLUE "--------------------"
  cecho WHITE "Task: The setuid binary suconnect allows socket connections. Use nc to listen on a port, connect via suconnect, and send the password to receive the next one."
  cat << 'EOF'
# SSH login
ssh bandit20@bandit.labs.overthewire.org -p 2220

# Once logged in (in one terminal):
nc -l ./backpipe  # Listen on a pipe or port

# In another terminal (same session):
./suconnect ./backpipe

# Send the level 20 password through the connection
EOF
  echo
  read -p "Press ENTER to see simulated output..."
  _prompt_action || return
  cecho GREEN "Simulated shell session:"
  cecho GREEN "bandit20@bandit:~$ nc -l ./backpipe &"
  cecho GREEN "[1] 1234"
  cecho GREEN "bandit20@bandit:~$ ./suconnect ./backpipe"
  cecho GREEN "[Enter level 20 password: 0qXahG8ZjOVMN9Ghs7iOWsCfZyXOUbYO]"
  cecho GREEN "In listener: EeoULMCra2q0dSkYj561DX7s1CpBuOBt"
  cecho GREEN "bandit20@bandit:~$ exit"
  echo
  cecho GREEN "Password found: EeoULMCra2q0dSkYj561DX7s1CpBuOBt"
  read -p "Run this yourself? When done, enter the password you found (or press ENTER to skip saving): " input
  if [[ -n "$input" ]]; then
    export BANDIT21_PASS="$input"
    cecho GREEN "Saved as BANDIT21_PASS."
  fi

  # Prompt to continue to next level (skips remaining levels in section if 'q')
  _prompt_action "Press ENTER to continue to next level, 'q' to skip remaining levels, 'Q' to quit: " || return 1
  
  # Level 22
  cecho BLUE "--------------------"
  cecho BOLD "2️⃣2️⃣ Bandit Level 22"
  cecho BLUE "--------------------"
  cecho WHITE "Task: A cron job runs /usr/bin/cronjob_bandit22.sh every minute, which copies the password to a temp file. Cat that file."
  cat << 'EOF'
# SSH login
ssh bandit21@bandit.labs.overthewire.org -p 2220

# Once logged in:
cat /usr/bin/cronjob_bandit22.sh
cat ./tmpxxxxxx  # The temp file name from the script
EOF
  echo
  read -p "Press ENTER to see simulated output..."
  _prompt_action || return
  cecho GREEN "Simulated shell session:"
  cecho GREEN "bandit21@bandit:~$ cat /usr/bin/cronjob_bandit22.sh"
  cecho GREEN "#!/bin/bash"
  cecho GREEN "chmod 644 ./tmprandom"
  cecho GREEN "cp /etc/bandit_pass/bandit22 ./tmprandom"
  cecho GREEN "bandit21@bandit:~$ cat ./tmprandom"
  cecho GREEN "tRae0UfB9v0UzbCdn9cY0gQnds9GF58Q"
  cecho GREEN "bandit21@bandit:~$ exit"
  echo
  cecho GREEN "Password found: tRae0UfB9v0UzbCdn9cY0gQnds9GF58Q"
  read -p "Run this yourself? When done, enter the password you found (or press ENTER to skip saving): " input
  if [[ -n "$input" ]]; then
    export BANDIT22_PASS="$input"
    cecho GREEN "Saved as BANDIT22_PASS."
  fi

  # Prompt to continue to next level (skips remaining levels in section if 'q')
  _prompt_action "Press ENTER to continue to next level, 'q' to skip remaining levels, 'Q' to quit: " || return 1
  
  # Level 23
  cecho BLUE "--------------------"
  cecho BOLD "2️⃣3️⃣ Bandit Level 23"
  cecho BLUE "--------------------"
  cecho WHITE "Task: Similar to 22, but the temp file name is the MD5 hash of 'I am user bandit23'."
  cat << 'EOF'
# SSH login
ssh bandit22@bandit.labs.overthewire.org -p 2220

# Once logged in:
cat /usr/bin/cronjob_bandit23.sh
HASH=$(echo -n "I am user bandit23" | md5sum | cut -d ' ' -f 1)
cat ./$HASH
EOF
  echo
  read -p "Press ENTER to see simulated output..."
  _prompt_action || return
  cecho GREEN "Simulated shell session:"
  cecho GREEN "bandit22@bandit:~$ echo -n 'I am user bandit23' | md5sum | cut -d ' ' -f 1"
  cecho GREEN "8ca319486bfbbc3663ea0fbe81326349"
  cecho GREEN "bandit22@bandit:~$ cat ./8ca319486bfbbc3663ea0fbe81326349"
  cecho GREEN "0Zf11ioIjMVN551jX3CmStKLYqjk54Ga"
  cecho GREEN "bandit22@bandit:~$ exit"
  echo
  cecho GREEN "Password found: 0Zf11ioIjMVN551jX3CmStKLYqjk54Ga"
  read -p "Run this yourself? When done, enter the password you found (or press ENTER to skip saving): " input
  if [[ -n "$input" ]]; then
    export BANDIT23_PASS="$input"
    cecho GREEN "Saved as BANDIT23_PASS."
  fi

  # Prompt to continue to next level (skips remaining levels in section if 'q')
  _prompt_action "Press ENTER to continue to next level, 'q' to skip remaining levels, 'Q' to quit: " || return 1
  
  # Level 24
  cecho BLUE "--------------------"
  cecho BOLD "2️⃣4️⃣ Bandit Level 24"
  cecho BLUE "--------------------"
  cecho WHITE "Task: The cron job runs and deletes scripts in /var/spool/bandit24/foo. Create a script there to copy the password to a readable file."
  cecho WHITE "Note for Git Bash/Windows: To avoid heredoc issues when pasting, we'll use 'echo' commands instead of multi-line heredoc."
  cat << 'EOF'
# SSH login
ssh bandit23@bandit.labs.overthewire.org -p 2220

# Once logged in (run these one by one):
mkdir -p ./my

# Create the script file using echo (safer for pasting):
echo '#!/bin/bash' > ./my/script
echo 'cat /etc/bandit_pass/bandit24 > ./my/password' >> ./my/script

# Verify the script was created:
cat ./my/script

# Copy and make executable:
cp ./my/script /var/spool/bandit24/foo/
chmod +x /var/spool/bandit24/foo/script

# Wait for cron (runs every 30 seconds, but wait 60 to be safe):
sleep 60

# Read the password:
cat ./my/password
EOF
  echo
  read -p "Press ENTER to see simulated output..."
  _prompt_action || return
  cecho GREEN "Simulated shell session:"
  cecho GREEN "bandit23@bandit:~$ echo '#!/bin/bash' > ./my/script"
  cecho GREEN "bandit23@bandit:~$ echo 'cat /etc/bandit_pass/bandit24 > ./my/password' >> ./my/script"
  cecho GREEN "bandit23@bandit:~$ cat ./my/script"
  cecho GREEN "#!/bin/bash"
  cecho GREEN "cat /etc/bandit_pass/bandit24 > ./my/password"
  cecho GREEN "bandit23@bandit:~$ cp ./my/script /var/spool/bandit24/foo/"
  cecho GREEN "bandit23@bandit:~$ chmod +x /var/spool/bandit24/foo/script"
  cecho GREEN "bandit23@bandit:~$ sleep 60"
  cecho GREEN "bandit23@bandit:~$ cat ./my/password"
  cecho GREEN "gb8KRRCsshuZXI0tUuR6ypOFjiZbf3G8"
  cecho GREEN "bandit23@bandit:~$ exit"
  echo
  cecho GREEN "Password found: gb8KRRCsshuZXI0tUuR6ypOFjiZbf3G8"
  read -p "Run this yourself? When done, enter the password you found (or press ENTER to skip saving): " input
  if [[ -n "$input" ]]; then
    export BANDIT24_PASS="$input"
    cecho GREEN "Saved as BANDIT24_PASS."
  fi

  # Prompt to continue to next level (skips remaining levels in section if 'q')
  _prompt_action "Press ENTER to continue to next level, 'q' to skip remaining levels, 'Q' to quit: " || return 1
  
  # Level 25
  cecho BLUE "--------------------"
  cecho BOLD "2️⃣5️⃣ Bandit Level 25"
  cecho BLUE "--------------------"
  cecho WHITE "Task: Brute-force a 4-digit PIN + level 24 password to connect to port 30002 via socat or nc."
  cat << 'EOF'
# SSH login
ssh bandit24@bandit.labs.overthewire.org -p 2220

# Once logged in:
seq -f "%04g $BANDIT24_PASS" 0 9999 | socat - TCP:localhost:30002
# Look for the line without "Wrong!"
EOF
  echo
  read -p "Press ENTER to see simulated output..."
  _prompt_action || return
  cecho GREEN "Simulated shell session:"
  cecho GREEN "bandit24@bandit:~$ seq -f '%04g gb8KRRCsshuZXI0tUuR6ypOFjiZbf3G8' 0 9999 | socat - TCP:localhost:30002 | grep -v Wrong!"
  cecho GREEN "6115 gb8KRRCsshuZXI0tUuR6ypOFjiZbf3G8"
  cecho GREEN "The password is iCi86ttT4KSNe1armKiwbQNmB3YJP3q4"
  cecho GREEN "bandit24@bandit:~$ exit"
  echo
  cecho GREEN "Password found: iCi86ttT4KSNe1armKiwbQNmB3YJP3q4"
  read -p "Run this yourself? When done, enter the password you found (or press ENTER to skip saving): " input
  if [[ -n "$input" ]]; then
    export BANDIT25_PASS="$input"
    cecho GREEN "Saved as BANDIT25_PASS."
  fi

  # Prompt to continue to next level (skips remaining levels in section if 'q')
  _prompt_action "Press ENTER to continue to next level, 'q' to skip remaining levels, 'Q' to quit: " || return 1
  
  # Level 26
  cecho BLUE "--------------------"
  cecho BOLD "2️⃣6️⃣ Bandit Level 26"
  cecho BLUE "--------------------"
  cecho WHITE "Task: Use the SSH key in bandit25's home to connect to bandit26. The shell runs 'more', escape to vi with 'vv', then edit the password file."
  cat << 'EOF'
# SSH login to 25
ssh bandit25@bandit.labs.overthewire.org -p 2220

# Copy key locally, chmod 600 bandit26.sshkey

# Connect with key:
ssh -i bandit26.sshkey bandit26@bandit.labs.overthewire.org -p 2220  # Make terminal small

# In the more prompt, press v (then v again for vi), :set shell=/bin/bash, :shell
# Then: cat /etc/bandit_pass/bandit26
EOF
  echo
  read -p "Press ENTER to see simulated output..."
  _prompt_action || return
  cecho GREEN "Simulated shell session:"
  cecho GREEN "bandit26@bandit:~$ # After escaping to shell"
  cecho GREEN "bandit26@bandit:~$ cat /etc/bandit_pass/bandit26"
  cecho GREEN "s0773xxkk0MXfdqOfPRVr9L3jJBUOgCZ"
  cecho GREEN "bandit26@bandit:~$ exit"
  echo
  cecho GREEN "Password found: s0773xxkk0MXfdqOfPRVr9L3jJBUOgCZ"
  read -p "Run this yourself? When done, enter the password you found (or press ENTER to skip saving): " input
  if [[ -n "$input" ]]; then
    export BANDIT26_PASS="$input"
    cecho GREEN "Saved as BANDIT26_PASS."
  fi

  # Prompt to continue to next level (skips remaining levels in section if 'q')
  _prompt_action "Press ENTER to continue to next level, 'q' to skip remaining levels, 'Q' to quit: " || return 1
  
  # Level 27
  cecho BLUE "--------------------"
  cecho BOLD "2️⃣7️⃣ Bandit Level 27"
  cecho BLUE "--------------------"
  cecho WHITE "Task: Similar to 26, escape the more shell to vi, get a shell, then use bandit27-do to cat the password."
  cat << 'EOF'
# SSH login
ssh bandit26@bandit.labs.overthewire.org -p 2220  # Small terminal

# Escape as in level 26 to get shell

# Then:
./bandit27-do cat /etc/bandit_pass/bandit27
EOF
  echo
  read -p "Press ENTER to see simulated output..."
  _prompt_action || return
  cecho GREEN "Simulated shell session:"
  cecho GREEN "bandit27@bandit:~$ ./bandit27-do cat /etc/bandit_pass/bandit27"
  cecho GREEN "upsNCc7vzaRDx6oZC6GiR6ERwe1MowGB"
  cecho GREEN "bandit27@bandit:~$ exit"
  echo
  cecho GREEN "Password found: upsNCc7vzaRDx6oZC6GiR6ERwe1MowGB"
  read -p "Run this yourself? When done, enter the password you found (or press ENTER to skip saving): " input
  if [[ -n "$input" ]]; then
    export BANDIT27_PASS="$input"
    cecho GREEN "Saved as BANDIT27_PASS."
  fi

  # Prompt to continue to next level (skips remaining levels in section if 'q')
  _prompt_action "Press ENTER to continue to next level, 'q' to skip remaining levels, 'Q' to quit: " || return 1
  
  # Level 28
  cecho BLUE "--------------------"
  cecho BOLD "2️⃣8️⃣ Bandit Level 28"
  cecho BLUE "--------------------"
  cecho WHITE "Task: Clone the git repo at ssh://bandit27-git@localhost:2220/home/bandit27-git/repo and cat README."
  cat << 'EOF'
# SSH login
ssh bandit27@bandit.labs.overthewire.org -p 2220

# Once logged in:
mkdir ./repo28
cd ./repo28
git clone ssh://bandit27-git@localhost:2220/home/bandit27-git/repo
cat repo/README
EOF
  echo
  read -p "Press ENTER to see simulated output..."
  _prompt_action || return
  cecho GREEN "Simulated shell session:"
  cecho GREEN "bandit27@bandit:./repo28$ git clone ssh://bandit27-git@localhost:2220/home/bandit27-git/repo"
  cecho GREEN "Cloning into 'repo'..."
  cecho GREEN "bandit27@bandit:./repo28$ cat repo/README"
  cecho GREEN "The password to the next level is: Yz9IpL0sBcCeuG7m9uQFt8ZNpS4HZRcN"
  cecho GREEN "bandit27@bandit:~$ exit"
  echo
  cecho GREEN "Password found: Yz9IpL0sBcCeuG7m9uQFt8ZNpS4HZRcN"
  read -p "Run this yourself? When done, enter the password you found (or press ENTER to skip saving): " input
  if [[ -n "$input" ]]; then
    export BANDIT28_PASS="$input"
    cecho GREEN "Saved as BANDIT28_PASS."
  fi

  # Prompt to continue to next level (skips remaining levels in section if 'q')
  _prompt_action "Press ENTER to continue to next level, 'q' to skip remaining levels, 'Q' to quit: " || return 1
  
  # Level 29
  cecho BLUE "--------------------"
  cecho BOLD "2️⃣9️⃣ Bandit Level 29"
  cecho BLUE "--------------------"
  cecho WHITE "Task: Clone the git repo, check git log -p on README.md to find the removed password in previous commit."
  cat << 'EOF'
# SSH login
ssh bandit28@bandit.labs.overthewire.org -p 2220

# Once logged in:
mkdir ./repo29
cd ./repo29
git clone ssh://bandit28-git@localhost:2220/home/bandit28-git/repo
cd repo
git log -p README.md
# Look for the diff where password was replaced with x's
EOF
  echo
  read -p "Press ENTER to see simulated output..."
  _prompt_action || return
  cecho GREEN "Simulated shell session:"
  cecho GREEN "bandit28@bandit:./repo29/repo$ git log -p README.md"
  cecho GREEN "diff --git a/README.md b/README.md"
  cecho GREEN "..."
  cecho GREEN "-The password to the next level is 4pT1t5DENaYuqnqvadYs1oE4QLCdjmJ7"
  cecho GREEN "+The password to the next level is xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
  cecho GREEN "bandit28@bandit:~$ exit"
  echo
  cecho GREEN "Password found: 4pT1t5DENaYuqnqvadYs1oE4QLCdjmJ7"
  read -p "Run this yourself? When done, enter the password you found (or press ENTER to skip saving): " input
  if [[ -n "$input" ]]; then
    export BANDIT29_PASS="$input"
    cecho GREEN "Saved as BANDIT29_PASS."
  fi

  # Prompt to continue to next level (skips remaining levels in section if 'q')
  _prompt_action "Press ENTER to continue to next level, 'q' to skip remaining levels, 'Q' to quit: " || return 1
  
  # Level 30
  cecho BLUE "--------------------"
  cecho BOLD "3️⃣0️⃣ Bandit Level 30"
  cecho BLUE "--------------------"
  cecho WHITE "Task: Clone the git repo, switch to dev branch (git checkout origin/dev), check log for password."
  cat << 'EOF'
# SSH login
ssh bandit29@bandit.labs.overthewire.org -p 2220

# Once logged in:
mkdir ./repo30
cd ./repo30
git clone ssh://bandit29-git@localhost:2220/home/bandit29-git/repo
cd repo
git checkout origin/dev
git log -p
# Find the password in the commit
EOF
  echo
  read -p "Press ENTER to see simulated output..."
  _prompt_action || return
  cecho GREEN "Simulated shell session:"
  cecho GREEN "bandit29@bandit:./repo30/repo$ git checkout origin/dev"
  cecho GREEN "bandit29@bandit:./repo30/repo$ git log -p"
  cecho GREEN "... password: qp30ex3VLz5MDG1n91YowTv4Q8l7CDZL ..."
  cecho GREEN "bandit29@bandit:~$ exit"
  echo
  cecho GREEN "Password found: qp30ex3VLz5MDG1n91YowTv4Q8l7CDZL"
  read -p "Run this yourself? When done, enter the password you found (or press ENTER to skip saving): " input
  if [[ -n "$input" ]]; then
    export BANDIT30_PASS="$input"
    cecho GREEN "Saved as BANDIT30_PASS."
  fi

  # Prompt to continue to next level (skips remaining levels in section if 'q')
  _prompt_action "Press ENTER to continue to next level, 'q' to skip remaining levels, 'Q' to quit: " || return 1
  
  # Level 31
  cecho BLUE "--------------------"
  cecho BOLD "3️⃣1️⃣ Bandit Level 31"
  cecho BLUE "--------------------"
  cecho WHITE "Task: Clone the git repo, list tags with git tag, then git show <tag> to reveal the password file."
  cat << 'EOF'
# SSH login
ssh bandit30@bandit.labs.overthewire.org -p 2220

# Once logged in:
mkdir ./repo31
cd ./repo31
git clone ssh://bandit30-git@localhost:2220/home/bandit30-git/repo
cd repo
git tag
git show secret
EOF
  echo
  read -p "Press ENTER to see simulated output..."
  _prompt_action || return
  cecho GREEN "Simulated shell session:"
  cecho GREEN "bandit30@bandit:./repo31/repo$ git tag"
  cecho GREEN "secret"
  cecho GREEN "bandit30@bandit:./repo31/repo$ git show secret"
  cecho GREEN "object abc123..."
  cecho GREEN "The password to the next level is fb5S2xb7bRyFmAvQYQGEqsbhVyJqhnDy"
  cecho GREEN "bandit30@bandit:~$ exit"
  echo
  cecho GREEN "Password found: fb5S2xb7bRyFmAvQYQGEqsbhVyJqhnDy"
  read -p "Run this yourself? When done, enter the password you found (or press ENTER to skip saving): " input
  if [[ -n "$input" ]]; then
    export BANDIT31_PASS="$input"
    cecho GREEN "Saved as BANDIT31_PASS."
  fi

  # Prompt to continue to next level (skips remaining levels in section if 'q')
  _prompt_action "Press ENTER to continue to next level, 'q' to skip remaining levels, 'Q' to quit: " || return 1
  
  # Level 32
  cecho BLUE "--------------------"
  cecho BOLD "3️⃣2️⃣ Bandit Level 32"
  cecho BLUE "--------------------"
  cecho WHITE "Task: Clone the git repo, create key.txt with 'May I come in?', add, commit, push to trigger hook and get password."
  cat << 'EOF'
# SSH login
ssh bandit31@bandit.labs.overthewire.org -p 2220

# Once logged in:
mkdir ./repo32
cd ./repo32
git clone ssh://bandit31-git@localhost:2220/home/bandit31-git/repo
cd repo
echo "May I come in?" > key.txt
git add key.txt
git commit -m "add key"
git push origin master
# The hook output contains the password
EOF
  echo
  read -p "Press ENTER to see simulated output..."
  _prompt_action || return
  cecho GREEN "Simulated shell session:"
  cecho GREEN "bandit31@bandit:./repo32/repo$ git push origin master"
  cecho GREEN "Counting objects: 4, done."
  cecho GREEN "The password to the next level is 3O9RfhqyAlVBEZpVb6LYStshZoqoSx5K"
  cecho GREEN "bandit31@bandit:~$ exit"
  echo
  cecho GREEN "Password found: 3O9RfhqyAlVBEZpVb6LYStshZoqoSx5K"
  read -p "Run this yourself? When done, enter the password you found (or press ENTER to skip saving): " input
  if [[ -n "$input" ]]; then
    export BANDIT32_PASS="$input"
    cecho GREEN "Saved as BANDIT32_PASS."
  fi

  # Prompt to continue to next level (skips remaining levels in section if 'q')
  _prompt_action "Press ENTER to continue to next level, 'q' to skip remaining levels, 'Q' to quit: " || return 1
  
  # Level 33 (last one)
  cecho BLUE "--------------------"
  cecho BOLD "3️⃣3️⃣ Bandit Level 33"
  cecho BLUE "--------------------"
  cecho WHITE "Task: The shell converts input to uppercase. Use \$0 to run the shell again normally, then cat the password."
  cat << 'EOF'
# SSH login
ssh bandit32@bandit.labs.overthewire.org -p 2220

# Once logged in (shell is uppercase):
$0  # Runs /usr/bin/showtext normally
# Now in normal shell: cat /etc/bandit_pass/bandit33
EOF
  echo
  read -p "Press ENTER to see simulated output..."
  _prompt_action || return
  cecho GREEN "Simulated shell session:"
  cecho GREEN "bandit32@bandit:~$ $0"
  cecho GREEN "bandit32@bandit:~$ cat /etc/bandit_pass/bandit33"
  cecho GREEN "tQdtbs5D5i2vJwkO8mEyYEyTL8izoeJ0"
  cecho GREEN "bandit32@bandit:~$ exit"
  echo
  cecho GREEN "Password found: tQdtbs5D5i2vJwkO8mEyYEyTL8izoeJ0"
  read -p "Run this yourself? When done, enter the password you found (or press ENTER to skip saving): " input
  if [[ -n "$input" ]]; then
    export BANDIT33_PASS="$input"
    cecho GREEN "Saved as BANDIT33_PASS."
  fi
  _prompt_action || return

  cecho GREEN "🎉 Congratulations! You've completed levels 0-33 of Bandit."
  cecho WHITE "Exported passwords (use 'echo \$BANDITXX_PASS' to view):"
  env | grep BANDIT | sort -V
  cecho WHITE "These teach advanced Linux skills: git, cron, setuid, networking, etc."
  cecho WHITE "Continue to higher levels on your own!"
}

section_command_subst() {
  cecho BLUE "===================================================="
  cecho BOLD "💻 COMMAND SUBSTITUTION DEMOS"
  cecho BLUE "===================================================="
  echo

  cecho WHITE "1. Command substitution"
  cecho WHITE "  - Use \$(cmd) instead of backticks for readability and nesting"
  cecho WHITE "  - Captures output of a command and inserts it into the current command"
  cecho WHITE "  - Useful for dynamic values like dates, counts, or file contents"
  echo

  TMP_TEST_FILE="./test_subst_file.txt"
  cat <<'EOF' > "$TMP_TEST_FILE"
Line 1: Hello
Line 2: World
Line 3: Bash
EOF

  cecho CYAN "Sample file created at: $TMP_TEST_FILE"
  echo
  cat "$TMP_TEST_FILE"
  echo
  _prompt_action || return

  cecho BLUE "------------------------------"
  cecho BOLD "1️⃣ BASIC COMMAND SUBSTITUTION"
  cecho BLUE "------------------------------"
  cat <<'EOF'
Example commands:
  a) echo "Today is $(date +%Y-%m-%d)"          → Insert current date
  b) echo "Lines in file: $(wc -l < file.txt)" → Count lines (no filename output)
  c) echo "Current user: $(whoami)"            → Insert username
  d) echo "Uptime: $(uptime 2>/dev/null || echo 'N/A')" → With fallback
EOF
  read -p "Press ENTER to run basic examples..."
  _prompt_action || return
  local today=$(date +%Y-%m-%d 2>/dev/null || echo 'N/A')
  cecho GREEN "a) echo \"Today is $today\""
  cecho GREEN "Today is $today"
  cecho GREEN "b) echo \"Lines in file: $(wc -l < $TMP_TEST_FILE)\""
  cecho GREEN "Lines in file: $(wc -l < $TMP_TEST_FILE)"
  cecho GREEN "c) echo \"Current user: $(whoami)\""
  cecho GREEN "Current user: $(whoami)"
  cecho GREEN "d) echo \"Uptime: $(uptime 2>/dev/null || echo 'N/A')\""
  cecho GREEN "Uptime: $(uptime 2>/dev/null || echo 'N/A')"
  _prompt_action || return

  cecho BLUE "------------------------------"
  cecho BOLD "2️⃣ NESTED & ADVANCED SUBSTITUTION"
  cecho BLUE "------------------------------"
  cat <<'EOF'
Example commands:
  a) echo "Processes: $(ps aux | wc -l)"       → Nested: count processes
  b) echo "Free RAM (MB): $(free -m 2>/dev/null | awk '/^Mem:/ {print $4}')" → Parse output
  c) VAR=$(grep "Bash" file.txt); echo "$VAR"  → Store in variable
  d) echo "Grep result: $(grep -c "Hello" file.txt)" → Count matches
EOF
  read -p "Press ENTER to run advanced examples..."
  _prompt_action || return
  cecho GREEN "a) echo \"Processes: \$(ps aux | wc -l)\""
  cecho GREEN "Processes: $(ps aux | wc -l 2>/dev/null || echo 'N/A')"
  cecho GREEN "b) echo \"Free RAM (MB): $(free -m 2>/dev/null | awk '/^Mem:/ {print \$4}')\""
  cecho GREEN "Free RAM (MB): $(free -m 2>/dev/null | awk '/^Mem:/ {print $4}' || echo 'N/A')"
  local grep_var=$(grep "Bash" "$TMP_TEST_FILE" 2>/dev/null || echo 'N/A')
  cecho GREEN "c) VAR=\$(grep \"Bash\" $TMP_TEST_FILE); echo \"\$VAR\""
  cecho GREEN "$grep_var"
  cecho GREEN "d) echo \"Grep result: \$(grep -c \"Hello\" $TMP_TEST_FILE)\""
  cecho GREEN "Grep result: $(grep -c "Hello" "$TMP_TEST_FILE" 2>/dev/null || echo 'N/A')"
  _prompt_action || return

  # Cleanup
  rm -f "$TMP_TEST_FILE"
  echo
}


section_quotes_escaping() {
  cecho BLUE "===================================================="
  cecho BOLD "📝 QUOTES & ESCAPING DEMOS"
  cecho BLUE "===================================================="
  echo

  cecho WHITE "1. Quotes and escaping"
  cecho WHITE "  - Single quotes (' '): Treat everything literally — no expansions or escapes inside"
  cecho WHITE "  - Double quotes (\" \"): Allow variable expansions and some escapes, but safer than no quotes"
  cecho WHITE "  - Backslash (\\): Escape special characters like $, \", ', or spaces in unquoted text"
  cecho WHITE "  - Why it matters: Prevents word splitting, globbing, and unexpected expansions"
  echo

  TMP_TEST_SCRIPT="./test_quotes.sh"
  cat <<'EOF' > "$TMP_TEST_SCRIPT"
#!/bin/bash
NAME="World"
echo "Double quotes: Hello, $NAME!"
echo 'Single quotes: Hello, $NAME'
echo "Escaped: He said, \"It\'s great!\" and costs \$10."
EOF

  cecho CYAN "Sample script created at: $TMP_TEST_SCRIPT"
  echo
  cat "$TMP_TEST_SCRIPT"
  echo
  # Prompt to continue to next level (skips remaining levels in section if 'q')
  _prompt_action "Press ENTER to continue to next level, 'q' to skip remaining levels, 'Q' to quit: " || return 1

  cecho BLUE "------------------------------"
  cecho BOLD "1️⃣ SINGLE vs DOUBLE QUOTES"
  cecho BLUE "------------------------------"
  cat <<'EOF'
Example commands:
  a) NAME="Friend"; echo "Double: Hello, $NAME"     → Expands variable
  b) NAME="Friend"; echo 'Single: Hello, $NAME'      → Literal $NAME (no expansion)
  c) echo "Unquoted: Hello $NAME"                    → May split/expand unexpectedly
EOF
  read -p "Press ENTER to run quotes examples..."
  _prompt_action || return
  local name_var="Friend"
  cecho GREEN "a) NAME=\"$name_var\"; echo \"Double: Hello, \$NAME\""
  NAME="$name_var"; echo "Double: Hello, $NAME"
  cecho GREEN "b) NAME=\"$name_var\"; echo 'Single: Hello, \$NAME'"
  NAME="$name_var"; echo 'Single: Hello, $NAME'
  cecho GREEN "c) echo \"Unquoted: Hello \$NAME\" (with var set)"
  echo "Unquoted: Hello $NAME"  # Note: This expands due to double quotes around the echo arg

  # Prompt to continue to next level (skips remaining levels in section if 'q')
  _prompt_action "Press ENTER to continue to next level, 'q' to skip remaining levels, 'Q' to quit: " || return 1

  cecho BLUE "------------------------------"
  cecho BOLD "2️⃣ ESCAPING SPECIAL CHARACTERS"
  cecho BLUE "------------------------------"
  cat <<'EOF'
Example commands:
  a) echo "He said, \"It\'s fine.\""                 → Escape inner quotes
  b) echo "Show dollar: \$100"                       → Escape $ to print literally
  c) echo 'He said, "It'\''s fine."'                 → Concat single quotes with escaped '
  d) ./test_quotes.sh                                → Run the sample script
EOF
  read -p "Press ENTER to run escaping examples..."
  _prompt_action || return
  cecho GREEN "a) echo \"He said, \\\"It'\\\'s fine.\\\"\""
  echo "He said, \"It's fine.\""
  cecho GREEN "b) echo \"Show dollar: \\\$100\""
  echo "Show dollar: \$100"
  cecho GREEN "c) echo 'He said, \"It'\''s fine.\"'"
  echo 'He said, "It'\''s fine."'
  cecho GREEN "d) ./$TMP_TEST_SCRIPT"
  chmod +x "$TMP_TEST_SCRIPT" 2>/dev/null
  ./"$TMP_TEST_SCRIPT"


  # Cleanup
  rm -f "$TMP_TEST_SCRIPT"
  echo
}

section_functions_arrays() {
  cecho BLUE "===================================================="
  cecho BOLD "⚙️ FUNCTIONS & ARRAYS DEMOS"
  cecho BLUE "===================================================="
  echo

  cecho WHITE "1. Functions: Define reusable code blocks with parameters"
  cecho WHITE "2. Arrays: Ordered lists; access by index"
  cecho WHITE "3. Associative arrays (Bash 4+): Key-value maps"
  echo

  TMP_TEST_SCRIPT="./test_functions_arrays.sh"
  cat <<'EOF' > "$TMP_TEST_SCRIPT"
#!/bin/bash

# Function example
greet() {
  local name="${1:-user}"
  printf "Hello, %s!\n" "$name"
}

# Array example
ARR=(alpha beta gamma delta)
echo "Array[0]: ${ARR[0]}"
echo "All elements: ${ARR[*]}"
echo "Length: ${#ARR[@]}"

# Associative array (if supported)
if declare -A >/dev/null 2>&1; then
  declare -A amap=( [name]=Alice [role]=engineer [age]=30 )
  echo "Assoc name: ${amap[name]}, role: ${amap[role]}"
  echo "Keys: ${!amap[*]}"
fi
EOF

  cecho CYAN "Sample script created at: $TMP_TEST_SCRIPT"
  echo
  cat "$TMP_TEST_SCRIPT"
  echo
  _prompt_action || return

  cecho BLUE "------------------------------"
  cecho BOLD "1️⃣ FUNCTIONS — Define and Call"
  cecho BLUE "------------------------------"
  cat <<'EOF'
Example commands:
  a) greet() { echo "Hello, $1!"; }; greet "Student"    → Define & call with arg
  b) add() { echo $(( $1 + $2 )); }; add 5 3             → Function with multiple args
EOF
  read -p "Press ENTER to run function examples..."
  _prompt_action || return
  cecho GREEN "a)"
  greet() { printf "Hello, %s!\n" "${1:-user}"; }
  greet "Student"
  cecho GREEN "b)"
  add() { echo $(( $1 + $2 )); }
  add 5 3
  _prompt_action || return

  cecho BLUE "------------------------------"
  cecho BOLD "2️⃣ ARRAYS — Indexed Lists"
  cecho BLUE "------------------------------"
  cat <<'EOF'
Example commands:
  a) ARR=(alpha beta gamma); echo "${ARR[0]}"           → Access by index
  b) echo "${ARR[*]}"                                   → All elements (space-separated)
  c) echo "${#ARR[@]}"                                  → Length (number of elements)
  d) ARR+=("delta"); echo "${ARR[*]}"                   → Append element
EOF
  read -p "Press ENTER to run array examples..."
  _prompt_action || return
  ARR=(alpha beta gamma)
  cecho GREEN "a) ARR=(alpha beta gamma); echo \"\${ARR[0]}\""
  echo "${ARR[0]}"
  cecho GREEN "b) echo \"\${ARR[*]}\""
  echo "${ARR[*]}"
  cecho GREEN "c) echo \"\${#ARR[@]}\""
  echo "${#ARR[@]}"
  ARR+=("delta")
  cecho GREEN "d) ARR+=(\"delta\"); echo \"\${ARR[*]}\""
  echo "${ARR[*]}"
  _prompt_action || return

  cecho BLUE "------------------------------"
  cecho BOLD "3️⃣ ASSOCIATIVE ARRAYS — Key-Value Maps (Bash 4+)"
  cecho BLUE "------------------------------"
  cat <<'EOF'
Example commands:
  a) declare -A amap=( [name]=Alice [role]=engineer )   → Declare & init
  b) echo "${amap[name]}"                               → Access by key
  c) echo "${!amap[*]}"                                 → All keys
  d) amap[age]=30; echo "${amap[age]}"                  → Add/update key
EOF
  read -p "Press ENTER to run assoc array examples..."
  _prompt_action || return
  if bash -c 'declare -A a >/dev/null 2>&1' 2>/dev/null; then
    declare -A amap=( [name]=Alice [role]=engineer )
    cecho GREEN "a) declare -A amap=( [name]=Alice [role]=engineer )"
    cecho GREEN "b) echo \"\${amap[name]}\""
    echo "${amap[name]}"
    cecho GREEN "c) echo \"\${!amap[*]}\""
    echo "${!amap[*]}"
    amap[age]=30
    cecho GREEN "d) amap[age]=30; echo \"\${amap[age]}\""
    echo "${amap[age]}"
  else
    cecho YELLOW "Associative arrays not supported in this Bash version. Skipping."
  fi
  _prompt_action || return

  # Run full script demo
  cecho BLUE "------------------------------"
  cecho BOLD "4️⃣ FULL SCRIPT DEMO"
  cecho BLUE "------------------------------"
  read -p "Press ENTER to run the sample script..."
  _prompt_action || return
  chmod +x "$TMP_TEST_SCRIPT" 2>/dev/null
  ./"$TMP_TEST_SCRIPT"

  # Cleanup
  rm -f "$TMP_TEST_SCRIPT"
  echo
}

section_read_getopts_printf() {
  cecho BLUE "===================================================="
  cecho BOLD "📖 READ, GETOPTS & PRINTF DEMOS"
  cecho BLUE "===================================================="
  echo

  cecho WHITE "1. read: Interactive input from user (with prompts, silent mode for passwords)"
  cecho WHITE "2. getopts: Parse command-line options (e.g., -a value -b)"
  cecho WHITE "3. printf: Formatted output (like C printf, safer than echo for complex formatting)"
  echo

  TMP_TEST_SCRIPT="./test_read_getopts_printf.sh"
  cat <<'EOF' > "$TMP_TEST_SCRIPT"
#!/bin/bash

# READ example
echo "Enter your name: "
read -r name
echo "Hello, $name!"

# READ -s for password
echo "Enter password (hidden): "
read -s password
echo -e "\nPassword length: ${#password}"

# GETOPTS example
while getopts ":a:b:" opt; do
  case $opt in
    a) echo "Option -a: $OPTARG" ;;
    b) echo "Option -b: $OPTARG" ;;
    *) echo "Unknown option" ;;
  esac
done

# PRINTF example
printf "%-20s | %5d | %s\n" "Item" 42 "Status"
printf "%-20s | %5d | %s\n" "Apple" 10 "In stock"
EOF

  cecho CYAN "Sample script created at: $TMP_TEST_SCRIPT"
  echo
  cat "$TMP_TEST_SCRIPT"
  echo
  _prompt_action || return

  cecho BLUE "------------------------------"
  cecho BOLD "1️⃣ READ — User Input"
  cecho BLUE "------------------------------"
  cat <<'EOF'
Example commands:
  a) read -r -p "Enter a string: " var; echo "You entered: $var"  → Prompted input (raw mode)
  b) read -s -p "Enter password: " pass; echo "Length: ${#pass}"   → Silent input (hidden chars)
  c) read -r -p "Name (default 'user'): " name; name=${name:-user}; echo "Hi, $name" → With default
EOF
  read -p "Press ENTER to run READ examples..."
  _prompt_action || return
  cecho GREEN "a)"
  read -r -p "Enter a sample string: " sample_input
  echo "You entered: $sample_input"
  cecho GREEN "b)"
  read -s -p "Enter a 'password' (hidden): " pass_input
  echo -e "\nLength: ${#pass_input}"
  cecho GREEN "c)"
  read -r -p "Name (default 'user'): " name_input
  name_input=${name_input:-user}
  echo "Hi, $name_input!"
  _prompt_action || return

  cecho BLUE "------------------------------"
  cecho BOLD "2️⃣ GETOPTS — Parse Command-Line Options"
  cecho BLUE "------------------------------"
  cat <<'EOF'
Example commands (simulate with 'set -- -a val1 -b val2'):
  a) while getopts ":a:b:" opt; do case $opt in a) echo "-a: $OPTARG";; b) echo "-b: $OPTARG";; esac; done
EOF
  read -p "Press ENTER to run GETOPTS examples..."
  _prompt_action || return
  cecho GREEN "a)"
  set -- -a apple -b banana
  while getopts ":a:b:" opt; do
    case $opt in
      a) cecho GREEN "  parsed -a -> $OPTARG" ;;
      b) cecho GREEN "  parsed -b -> $OPTARG" ;;
      *) cecho GREEN "  unknown opt" ;;
    esac
  done
  # Restore positional params
  set --
  _prompt_action || return

  cecho BLUE "------------------------------"
  cecho BOLD "3️⃣ PRINTF — Formatted Output"
  cecho BLUE "------------------------------"
  cat <<'EOF'
Example commands:
  a) printf "%-10s | %03d | %s\n" "Item" 7 "ok"         → Left-align, zero-pad, literal
  b) printf "Price: \$%.2f\n" 19.99                      → Escape $, format float
  c) printf "%s says: %s\n" "User" "Hello"               → Simple substitution
EOF
  read -p "Press ENTER to run PRINTF examples..."
  _prompt_action || return
  local sample_str="demo"
  cecho GREEN "a) printf \"%-10s | %03d | %s\\n\" \"$sample_str\" 7 \"ok\""
  printf "%-10s | %03d | %s\n" "$sample_str" 7 "ok"
  cecho GREEN "b) printf \"Price: \\\$%.2f\\n\" 19.99"
  printf "Price: \$%.2f\n" 19.99
  cecho GREEN "c) printf \"%s says: %s\\n\" \"User\" \"Hello\""
  printf "%s says: %s\n" "User" "Hello"
  _prompt_action || return

  # Full script demo
  cecho BLUE "------------------------------"
  cecho BOLD "4️⃣ FULL SCRIPT DEMO"
  cecho BLUE "------------------------------"
  read -p "Press ENTER to run the sample script (interactive prompts)..."
  _prompt_action || return
  chmod +x "$TMP_TEST_SCRIPT" 2>/dev/null
  ./"$TMP_TEST_SCRIPT"

  # Cleanup
  rm -f "$TMP_TEST_SCRIPT"
  echo

  # Prompt to continue to next section (skips remaining sections if 'q')
  _prompt_action "Press ENTER to continue to next section, 'q' to skip remaining sections, 'Q' to quit: " || return 1
}

section_redirection_fd() {
  cecho BLUE "===================================================="
  cecho BOLD "🔄 REDIRECTIONS & FILE DESCRIPTORS DEMOS"
  cecho BLUE "===================================================="
  echo

  cecho WHITE "1. Redirections: Control where input/output goes (> stdout, >> append, 2> stderr, &> both, < input)"
  cecho WHITE "2. File Descriptors (FD): Numbers for streams (0=stdin, 1=stdout, 2=stderr); duplicate with exec N>&M"
  cecho WHITE "   - Useful for logging, piping, or preserving original output while redirecting copies"
  echo

  TMP_TEST_SCRIPT="./test_redirection_fd.sh"
  TMP_LOG_FILE="./test_log.txt"
  cat <<'EOF' > "$TMP_TEST_SCRIPT"
#!/bin/bash

# Redirection examples
echo "Sample input text" > input.txt # Ensure input file exists
echo "stdout to file" > output.txt
echo "stderr to file" 2> error.txt
echo "both to file" &> combined.txt
cat < input.txt  # Read from file

# FD duplication example
exec 3> log.txt  # Open FD3 for writing to log
echo "Log via FD3" >&3
echo "Normal stdout still works"  # Goes to terminal
exec 3>&-  # Close FD3
cat log.txt
EOF

  cecho CYAN "Sample script created at: $TMP_TEST_SCRIPT"
  echo
  cat "$TMP_TEST_SCRIPT"
  echo
  _prompt_action || return

  cecho BLUE "------------------------------"
  cecho BOLD "1️⃣ BASIC REDIRECTIONS"
  cecho BLUE "------------------------------"
  cat <<'EOF'
Example commands:
  a) echo "Hello" > file.txt; cat file.txt              → Overwrite stdout to file
  b) echo "Append" >> file.txt; cat file.txt             → Append to file
  c) ls nonexist 2> error.txt; cat error.txt             → Redirect stderr
  d) echo "Both" &> combined.txt; cat combined.txt       → Stdout + stderr to file
  e) cat < file.txt                                      → Redirect file to stdin
EOF
  read -p "Press ENTER to run basic redirection examples..."
  _prompt_action || return
  local test_file="./redir_test.txt"
  cecho GREEN "a) echo \"Hello\" > $test_file; cat $test_file"
  echo "Hello" > "$test_file"
  cat "$test_file"
  cecho GREEN "b) echo \"Append\" >> $test_file; cat $test_file"
  echo "Append" >> "$test_file"
  cat "$test_file"
  cecho GREEN "c) ls nonexist 2> ./error.txt; cat ./error.txt"
  ls nonexist 2> ./error.txt 2>/dev/null || true
  cat ./error.txt 2>/dev/null || echo "No error (ls succeeded)"
  cecho GREEN "d) echo \"Both\" &> ./combined.txt; cat ./combined.txt"
  echo "Both" &> ./combined.txt
  cat ./combined.txt
  echo "Hello" > "$test_file"  # Reset for e
  cecho GREEN "e) cat < $test_file"
  cat < "$test_file"
  _prompt_action || return

  cecho BLUE "------------------------------"
  cecho BOLD "2️⃣ FILE DESCRIPTOR DUPLICATION"
  cecho BLUE "------------------------------"
  cat <<'EOF'
Example commands:
  a) exec 3> log.txt; echo "Log" >&3; cat log.txt       → Duplicate stdout to FD3 (file)
  b) exec 3>&1; echo "To FD3" >&3; exec 3>&-            → Duplicate to original stdout
  c) command 2>&1 | grep error                           → Merge stderr to stdout for pipe
EOF
  read -p "Press ENTER to run FD examples..."
  _prompt_action || return
  local fd_log="./fd_log.txt"
  > "$fd_log"  # Clear log
  cecho GREEN "a) exec 3> $fd_log; echo \"Log\" >&3; cat $fd_log"
  exec 3> "$fd_log"
  echo "Log" >&3
  exec 3>&-
  cat "$fd_log"
  cecho GREEN "b) exec 3>&1; echo \"To FD3\" >&3; exec 3>&-"
  exec 3>&1
  echo "To FD3" >&3
  exec 3>&-
  cecho GREEN "c) ls nonexist 2>&1 | head -1"
  ls nonexist 2>&1 | head -1 2>/dev/null || echo "ls nonexist: No such file or directory"
  _prompt_action || return

  # Full script demo
  cecho BLUE "------------------------------"
  cecho BOLD "3️⃣ FULL SCRIPT DEMO"
  cecho BLUE "------------------------------"
  read -p "Press ENTER to run the sample script..."
  _prompt_action || return
  chmod +x "$TMP_TEST_SCRIPT" 2>/dev/null
  ./"$TMP_TEST_SCRIPT"
  echo "Sample output files created (check with ls ./output* ./log.txt)"

  # Cleanup
  rm -f "$TMP_TEST_SCRIPT" "$TMP_LOG_FILE" ./redir_test.txt ./error.txt ./combined.txt ./fd_log.txt ./output.txt ./error.txt ./combined.txt ./log.txt 2>/dev/null
  echo

  # Prompt to continue to next section (skips remaining sections if 'q')
  _prompt_action "Press ENTER to continue to next section, 'q' to skip remaining sections, 'Q' to quit: " || return 1
}

section_heredoc_procsub() {
  cecho BLUE "===================================================="
  cecho BOLD "📄 HEREDOC & PROCESS SUBSTITUTION DEMOS"
  cecho BLUE "===================================================="
  echo

  cecho WHITE "1. Heredoc (<<EOF ... EOF): Multi-line input to commands or string creation"
  cecho WHITE "   - Use <<'EOF' for literal (no expansion); <<EOF for expansion"
  cecho WHITE "   - Great for scripts, emails, config files, or command input"
  cecho WHITE "2. Process Substitution (<(cmd) or >(cmd)): Treat command output as file"
  cecho WHITE "   - <(cmd): Input from command (e.g., sort <(ls))"
  cecho WHITE "   - >(cmd): Output to command (e.g., tee >(grep error))"
  echo

  TMP_TEST_SCRIPT="./test_heredoc_procsub.sh"
  cat <<'OUTER_EOF' > "$TMP_TEST_SCRIPT"
#!/bin/bash

# Heredoc example: Multi-line input to cat
cat <<'INNER_1'
This is a literal heredoc.
No expansions: $VAR stays as-is.
INNER_1

cat <<INNER_2
This expands: $VAR
INNER_2

# Heredoc with expansion
VAR="World"
cat <<INNER_3
This expands: Hello $VAR!
INNER_3

# Process substitution: Diff two command outputs
diff <(printf 'apple\nbanana\n') <(printf 'apple\ncherry\n') || echo "Differences detected (expected)"

# Process substitution: Sort and compare
sort <(echo -e "banana\napple") > sorted1.txt
sort <(ls . | head -3) > sorted2.txt
diff sorted1.txt sorted2.txt || echo "Files differ (demo)"
OUTER_EOF

  cecho CYAN "Sample script created at: $TMP_TEST_SCRIPT"
  echo
  cat "$TMP_TEST_SCRIPT"
  echo
  _prompt_action || return

  cecho BLUE "------------------------------"
  cecho BOLD "1️⃣ HEREDOC — Multi-Line Input"
  cecho BLUE "------------------------------"
  cat <<'EOF'
Example commands:
  a) cat <<'EOF' > file.txt; ...; EOF                  → Literal heredoc to file
  b) cat <<EOF; echo "Hi $USER"; EOF                   → Expanding heredoc
  c) wc -l <<'HEREDOC'; line1; line2; HEREDOC          → Count lines from heredoc
EOF
  read -p "Press ENTER to run HEREDOC examples..."
  _prompt_action || return
  local heredoc_file="./heredoc_test.txt"
  cecho GREEN "a) cat <<'EOF' > $heredoc_file"
  cat <<'EOF' > "$heredoc_file"
Literal line 1
Literal line 2: $NO_EXPAND
EOF
  cat "$heredoc_file"
  cecho GREEN "b) cat <<EOF"
  local user_var="${USER:-user}"
  cat <<EOF
Expanding: Hello $user_var!
EOF
  cecho GREEN "c) wc -l <<'HEREDOC'"
  wc -l <<'HEREDOC'
Short heredoc.
Two lines.
HEREDOC
  _prompt_action || return

  cecho BLUE "------------------------------"
  cecho BOLD "2️⃣ PROCESS SUBSTITUTION — Command as File"
  cecho BLUE "------------------------------"
  cat <<'EOF'
Example commands:
  a) diff <(echo "a"; echo "b") <(echo "a"; echo "c")   → Compare command outputs
  b) sort <(ls /tmp) | head -3                          → Sort and limit output
  c) tee >(grep "error" > errors.log)                   → Duplicate output to file via grep
EOF
  read -p "Press ENTER to run process substitution examples..."
  _prompt_action || return
  cecho GREEN "a) diff <(echo \"a\"; echo \"b\") <(echo \"a\"; echo \"c\")"
  diff <(echo "a"; echo "b") <(echo "a"; echo "c") || cecho YELLOW "Differences shown (expected)"
  cecho GREEN "b) sort <(ls /tmp | head -5) | head -3"
  sort <(ls /tmp 2>/dev/null | head -5) | head -3 || echo "No /tmp files or limited output"
  local errors_log="./errors_demo.log"
  > "$errors_log"  # Clear
  cecho GREEN "c) echo \"error line\" | tee >(grep \"error\" > $errors_log)"
  echo "error line" | tee >(grep "error" > "$errors_log")
  echo "Non-error line" | tee >(grep "error" > "$errors_log")
  cat "$errors_log"
  _prompt_action || return

  # Full script demo
  cecho BLUE "------------------------------"
  cecho BOLD "3️⃣ FULL SCRIPT DEMO"
  cecho BLUE "------------------------------"
  read -p "Press ENTER to run the sample script..."
  _prompt_action || return
  chmod +x "$TMP_TEST_SCRIPT" 2>/dev/null
  ./"$TMP_TEST_SCRIPT"

  # Cleanup
  rm -f "$TMP_TEST_SCRIPT" "$heredoc_file" "$errors_log" ./sorted1.txt ./sorted2.txt 2>/dev/null
  echo

  # Prompt to continue to next section (skips remaining sections if 'q')
  _prompt_action "Press ENTER to continue to next section, 'q' to skip remaining sections, 'Q' to quit: " || return 1
}

section_error_handling_trap() {
  cecho BLUE "===================================================="
  cecho BOLD "🛡️ ERROR HANDLING & TRAP DEMOS"
  cecho BLUE "===================================================="
  echo

  cecho WHITE "1. Error Handling: Use 'set -e' for exit on error, || for alternatives, && for chaining"
  cecho WHITE "   - $? : Exit status (0=success, non-zero=error)"
  cecho WHITE "2. Trap: Catch signals (e.g., SIGINT, EXIT) to run cleanup or logging"
  cecho WHITE "   - trap 'cmd' SIGNAL; trap - RESET"
  echo

  TMP_TEST_SCRIPT="./test_error_trap.sh"
  cat <<'EOF' > "$TMP_TEST_SCRIPT"
#!/bin/bash

# Error handling example
set -e  # Exit on any command failure
false && echo "This won't run"
echo "If set -e, script stops on error"

# || and && chaining
true && echo "Success chain"
false || echo "Error alternative"

# Trap example
trap 'echo "Cleanup: Removing temp files" && rm -f ./demo_*' EXIT
trap 'echo "Interrupted! Cleaning up"' INT

echo "Running main task..."
sleep 2  # Simulate work
touch ./demo_file
echo "Task complete"
EOF

  cecho CYAN "Sample script created at: $TMP_TEST_SCRIPT"
  echo
  cat "$TMP_TEST_SCRIPT"
  echo
  _prompt_action || return

  cecho BLUE "------------------------------"
  cecho BOLD "1️⃣ BASIC ERROR HANDLING"
  cecho BLUE "------------------------------"
  cat <<'EOF'
Example commands:
  a) set -e; false; echo "This won't print"           → Exit on error (set -e)
  b) false || echo "Handled error"                     → Alternative on failure
  c) true && echo "Success only"                       → Chain on success
  d) ls . | head -n 5; if [ $? -eq 0 ]; then echo "OK"; else echo "Failed"; fi → Check exit status
EOF
  read -p "Press ENTER to run error handling examples..."
  _prompt_action || return
  cecho GREEN "a) set -e; false; echo \"Won't reach here\""
  (set -e; false; echo "Won't reach here")  # Subshell to avoid exiting
  cecho GREEN "b) false || echo \"Handled error\""
  false || echo "Handled error"
  cecho GREEN "c) true && echo \"Success only\""
  true && echo "Success only"
  cecho GREEN "d) ls . | head -n 5; if [ \$? -eq 0 ]; then echo \"OK\"; else echo \"Failed\"; fi"
  ls . 2>/dev/null | head -n 5 || true
  if [ $? -eq 0 ]; then echo "OK"; else echo "Failed"; fi
  _prompt_action || return

  cecho BLUE "------------------------------"
  cecho BOLD "2️⃣ TRAP — Signal Handling"
  cecho BLUE "------------------------------"
  cat <<'EOF'
Example commands:
  a) trap 'echo "Trapped EXIT"' EXIT; echo "End"        → Run on script exit
  b) trap 'echo "Interrupted"' INT; sleep 5; echo "Continues" → Catch Ctrl+C
  c) trap '' INT; sleep 5                               → Ignore signal
  d) trap - INT                                         → Reset trap
EOF
  read -p "Press ENTER to run TRAP examples (press Ctrl+C on sleep to test INT)..."
  _prompt_action || return
  cecho GREEN "a) trap 'echo \"Trapped EXIT\"' EXIT; echo \"Running...\"; echo \"End\""
  (trap 'echo "Trapped EXIT"' EXIT; echo "Running..."; echo "End")
  cecho GREEN "b) trap 'echo \"Interrupted\"' INT; sleep 3 & wait \$!"
  (trap 'echo "Interrupted"' INT; sleep 3 & wait $!)
  cecho GREEN "c) trap '' INT; sleep 3 & wait \$!  # Ignores Ctrl+C"
  (trap '' INT; sleep 3 & wait $!)
  cecho GREEN "d) trap - INT  # Reset (default behavior)"
  trap - INT  # Just reset if set
  _prompt_action || return

  # Full script demo
  cecho BLUE "------------------------------"
  cecho BOLD "3️⃣ FULL SCRIPT DEMO"
  cecho BLUE "------------------------------"
  read -p "Press ENTER to run the sample script (try Ctrl+C to test trap)..."
  _prompt_action || return
  chmod +x "$TMP_TEST_SCRIPT" 2>/dev/null
  ./"$TMP_TEST_SCRIPT"

  # Cleanup
  rm -f "$TMP_TEST_SCRIPT" ./demo_file 2>/dev/null
  echo

  # Prompt to continue to next section (skips remaining sections if 'q')
  _prompt_action "Press ENTER to continue to next section, 'q' to skip remaining sections, 'Q' to quit: " || return 1
}

section_coproc_jobcontrol() {
  cecho BLUE "===================================================="
  cecho BOLD "🔄 COPROC & JOB CONTROL DEMOS"
  cecho BLUE "===================================================="
  echo

  cecho WHITE '1. Coproc: Run a background co-process for bidirectional communication'
  cecho WHITE '   - coproc NAME { CMD }; read/write via ${NAME[0]} (read) / ${NAME[1]} (write)'
  cecho WHITE '2. Job Control: Manage background jobs with bg, fg, jobs, &'
  cecho WHITE '   - & : Background, jobs : List, fg %N : Foreground job N, kill %N : Kill job'
  echo

  TMP_TEST_SCRIPT="./test_coproc_job.sh"
  cat <<'EOF' > "$TMP_TEST_SCRIPT"
#!/bin/bash

# Coproc example: Simulate a chat-like process
coproc CHAT_PROC {
  echo "Chatbot: Hello! Type 'quit' to exit."
  while true; do
    read -r msg
    if [[ "$msg" == "quit" ]]; then
      echo "Chatbot: Goodbye!"
      break
    fi
    echo "Chatbot: You said: $msg"
  done
}

echo "User: Hi there!" >&"${CHAT_PROC[1]}"
read -r -u "${CHAT_PROC[0]}" response
echo "Response: $response"

# Simulate job control: Background a task
(sleep 5; echo "Background job done!") &
BG_JOB=$!

# Wait and check
wait $BG_JOB
echo "Job $BG_JOB completed."

# Cleanup coproc
exec {CHAT_PROC[0]}>&- {CHAT_PROC[1]}>&-

echo "Demo complete"
EOF

  cecho CYAN "Sample script created at: $TMP_TEST_SCRIPT"
  echo
  cat "$TMP_TEST_SCRIPT"
  echo
  _prompt_action || return

  cecho BLUE "------------------------------"
  cecho BOLD "1️⃣ BASIC COPROC"
  cecho BLUE "------------------------------"
  cat <<'EOF'
Example commands:
  a) coproc P { echo "Proc: Hello"; sleep 1; echo "Proc: Bye"; }; read -u ${P[0]} line; echo "$line"
  b) coproc P { while read -u ${COPROC[1]} msg; do echo "Echo: $msg"; done; }; echo "Test" >&${P[1]}
  c) exec {P[0]}>&- {P[1]}>&-  → Close coproc FDs
EOF
  read -p "Press ENTER to run coproc examples..."
  _prompt_action || return
  cecho GREEN "a) Simple coproc read"
  (coproc P { echo "Proc: Hello"; sleep 1; echo "Proc: Bye"; }; read -r -t 2 -u "${P[0]}" line; echo "Read: $line"; exec {P[0]}>&- {P[1]}>&-)
  cecho GREEN "b) Coproc echo (write from main)"
  (coproc P { while read -r -u "${COPROC[1]}" msg; do echo "Echo: $msg"; sleep 0.5; done; }; echo "Test msg" >&"${P[1]}"; read -r -t 2 -u "${P[0]}" out; echo "Output: $out"; exec {P[0]}>&- {P[1]}>&-)
  cecho GREEN "c) Closing FDs (demo only)"
  echo "FDs closed manually in examples above"
  _prompt_action || return

  cecho BLUE "------------------------------"
  cecho BOLD "2️⃣ JOB CONTROL"
  cecho BLUE "------------------------------"
  cat <<'EOF'
Example commands:
  a) sleep 5 &; echo "Job PID: $!"                          → Background with PID
  b) jobs -l                                                  → List jobs with PIDs
  c) sleep 10 &; fg %1                                        → Foreground last job
  d) sleep 3 &; kill %1; jobs                                 → Kill and list
EOF
  read -p "Press ENTER to run job control examples..."
  _prompt_action || return
  cecho GREEN "a) sleep 5 &; echo \"Job PID: \$!\""
  (sleep 5 & echo "Job PID: $!"; wait %1)
  cecho GREEN "b) jobs -l (run a quick job)"
  (sleep 2 & JOBS_PID=$!; jobs -l; wait $JOBS_PID)
  cecho GREEN "c) sleep 10 &; fg %1  # Brings to foreground"
  echo "Starting background sleep 10... (it will fg and complete)"
  (sleep 10 & fg %1)
  cecho GREEN "d) sleep 3 &; kill %1; jobs"
  (sleep 3 & KILL_PID=$!; sleep 1; kill %1 2>/dev/null || true; jobs)
  _prompt_action || return

  # Full script demo
  cecho BLUE "------------------------------"
  cecho BOLD "3️⃣ FULL SCRIPT DEMO"
  cecho BLUE "------------------------------"
  read -p "Press ENTER to run the sample script..."
  _prompt_action || return
  chmod +x "$TMP_TEST_SCRIPT" 2>/dev/null
  ./"$TMP_TEST_SCRIPT"

  # Cleanup
  rm -f "$TMP_TEST_SCRIPT" 2>/dev/null
  echo

  # Prompt to continue to next section (skips remaining sections if 'q')
  _prompt_action "Press ENTER to continue to next section, 'q' to skip remaining sections, 'Q' to quit: " || return 1
}

section_mapfile_readarray() {
  cecho BLUE "===================================================="
  cecho BOLD "📚 MAPFILE & READARRAY DEMOS"
  cecho BLUE "===================================================="
  echo

  cecho WHITE '1. mapfile/readarray: Efficiently read lines from stdin/file into an array'
  cecho WHITE '   - mapfile -t arr < file  (strips trailing newlines with -t)'
  cecho WHITE '   - readarray -t arr < file  (alias for mapfile, same options)'
  cecho WHITE '   - Options: -n N (first N lines), -O start (start index), -d delim (custom delimiter)'
  cecho WHITE '2. Array Usage: Iterate with for i in "${!arr[@]}"; or "${arr[@]}"'
  echo

  TMP_TEST_SCRIPT="./test_mapfile_readarray.sh"
  cat <<'EOF' > "$TMP_TEST_SCRIPT"
#!/bin/bash

# Create sample data file
cat <<'DATA' > ./sample_lines.txt
Line 1: Apple
Line 2: Banana
Line 3: Cherry
Line 4: Date
DATA

# Read full file into array
mapfile -t fruits < ./sample_lines.txt
echo "Full array (${#fruits[@]} elements):"
for i in "${!fruits[@]}"; do
  echo "  [$i] ${fruits[i]}"
done

# Read first 2 lines only
readarray -t -n 2 short_fruits < ./sample_lines.txt
echo "First 2 lines:"
printf '  %s\n' "${short_fruits[@]}"

# Process: Uppercase and print
declare -U upper_fruits=("${fruits[@]}")  # Bash 5+ for uppercase, or use awk/tr
echo "Uppercase versions (using awk for portability):"
for line in "${fruits[@]}"; do
  echo "  $(echo "$line" | awk '{print toupper($0)}')"
done

# Cleanup
rm -f ./sample_lines.txt
echo "Demo complete"
EOF

  cecho CYAN "Sample script created at: $TMP_TEST_SCRIPT"
  echo
  cat "$TMP_TEST_SCRIPT"
  echo
  _prompt_action || return

  cecho BLUE "------------------------------"
  cecho BOLD "1️⃣ BASIC MAPFILE/READARRAY"
  cecho BLUE "------------------------------"
  cat <<'EOF'
Example commands:
  a) printf 'apple\nbanana\ngamma\n' > file; mapfile -t arr < file; echo "${arr[0]}"
  b) readarray -t -n 2 arr < file  → Read first 2 lines
  c) mapfile -t -O 1 arr < file   → Start array at index 1
  d) for i in "${!arr[@]}"; do echo "[$i] ${arr[i]}"; done  → Iterate with indices
EOF
  read -p "Press ENTER to run mapfile/readarray examples..."
  _prompt_action || return

  # Ensure TMP_LINES exists
  printf '%s\n' "apple" "banana" "cherry" > "$TMP_LINES"

  cecho GREEN "a) mapfile -t arr < file; echo \"\${arr[0]}\""
  (mapfile -t arr < "$TMP_LINES"; echo "${arr[0]}")
  cecho GREEN "b) readarray -t -n 2 arr < file"
  (readarray -t -n 2 arr < "$TMP_LINES"; printf '  %s\n' "${arr[@]}")
  cecho GREEN "c) mapfile -t -O 1 arr < file  # Starts at index 1"
  (mapfile -t -O 1 arr < "$TMP_LINES"; echo "Length: ${#arr[@]}"; echo "[1]: ${arr[1]}")
  cecho GREEN "d) Iterate over array"
  (mapfile -t arr < "$TMP_LINES"; for i in "${!arr[@]}"; do echo "[$i] ${arr[i]}"; done)
  _prompt_action || return

  cecho BLUE "------------------------------"
  cecho BOLD "2️⃣ ADVANCED OPTIONS & USAGE"
  cecho BLUE "------------------------------"
  cat <<'EOF'
Example commands:
  a) mapfile -d ',' -t arr <<< 'a,b,c'  → Custom delimiter (CSV-like)
  b) readarray -u 3 -t arr < file      → Read from FD 3 (redirected)
  c) declare -a arr; mapfile -t arr <<< $'line1\nline2'  → From heredoc/variable
EOF
  read -p "Press ENTER to run advanced examples..."
  _prompt_action || return
  cecho GREEN "a) mapfile -d ',' -t arr <<< 'a,b,c'"
  (mapfile -d ',' -t arr <<< 'a,b,c'; printf '  %s\n' "${arr[@]}")
  cecho GREEN "b) exec 3< file; readarray -u 3 -t arr"
  (exec 3< "$TMP_LINES"; readarray -u 3 -t arr; echo "From FD 3: ${arr[0]}"; exec 3>&-)
  cecho GREEN "c) mapfile -t arr <<< \$'line1\\nline2'"
  (mapfile -t arr <<< $'line1\nline2'; echo "From heredoc: ${#arr[@]} lines")
  _prompt_action || return

  # Full script demo
  cecho BLUE "------------------------------"
  cecho BOLD "3️⃣ FULL SCRIPT DEMO"
  cecho BLUE "------------------------------"
  read -p "Press ENTER to run the sample script..."
  _prompt_action || return
  chmod +x "$TMP_TEST_SCRIPT" 2>/dev/null
  ./"$TMP_TEST_SCRIPT"

  # Cleanup
  rm -f "$TMP_TEST_SCRIPT" ./sample_lines.txt 2>/dev/null
  echo

  # Prompt to continue to next section (skips remaining sections if 'q')
  _prompt_action "Press ENTER to continue to next section, 'q' to skip remaining sections, 'Q' to quit: " || return 1
}

section_automation_sample() {
  cecho BLUE "===================================================="
  cecho BOLD "🚀 SAMPLE AUTOMATION DEMOS"
  cecho BLUE "===================================================="
  echo

  cecho WHITE '1. Automation Basics: Script repetitive tasks like file/dir management'
  cecho WHITE '   - mkdir -p DIR: Create dir (no error if exists)'
  cecho WHITE '   - touch FILE: Create empty file or update timestamp'
  cecho WHITE '   - rm -rf DIR: Safe cleanup (use cautiously!)'
  cecho WHITE '2. Best Practices: Use $$ for PID in temp names, error checks with ||'
  cecho WHITE '   - Temp dirs: Avoid conflicts with unique names like "dir_$$"'
  echo

  TMP_TEST_SCRIPT="./test_automation_sample.sh"
  cat <<'EOF' > "$TMP_TEST_SCRIPT"
#!/bin/bash

# Sample automation: Backup-like task
BACKUP_DIR="backup_$(date +%Y%m%d)_$$"
echo "Starting automation: Creating backup dir $BACKUP_DIR"

# Step 1: Create backup dir
mkdir -p "$BACKUP_DIR" || { echo "Error: mkdir failed"; exit 1; }
echo "  ✓ Dir created: $BACKUP_DIR"

# Step 2: "Backup" sample files (simulate with touch)
touch "$BACKUP_DIR"/file1.txt "$BACKUP_DIR"/file2.log
echo "  ✓ Files created: file1.txt, file2.log"
ls -l "$BACKUP_DIR"

# Step 3: Simulate processing (e.g., tar)
tar -cf "$BACKUP_DIR.tar" -C "$(dirname "$BACKUP_DIR")" "$(basename "$BACKUP_DIR")" || { echo "Error: tar failed"; exit 1; }
echo "  ✓ Archive created: $BACKUP_DIR.tar"

# Step 4: Cleanup temp dir
rm -rf "$BACKUP_DIR"
echo "  ✓ Temp dir cleaned up"

# Keep archive
echo "Automation complete: $BACKUP_DIR.tar ready"
EOF

  cecho CYAN "Sample script created at: $TMP_TEST_SCRIPT"
  echo
  cat "$TMP_TEST_SCRIPT"
  echo
  _prompt_action || return

  cecho BLUE "------------------------------"
  cecho BOLD "1️⃣ BASIC AUTOMATION"
  cecho BLUE "------------------------------"
  cat <<'EOF'
Example commands:
  a) D="demo_$$"; mkdir -p "$D"; touch "$D"/file.txt; ls "$D"
  b) rm -rf "$D"  → Cleanup
  c) mkdir -p "$D" || { echo "Failed"; exit 1; }  → Error handling
  d) date +%Y%m%d_$$  → Unique timestamp + PID for names
EOF
  read -p "Press ENTER to run basic automation examples..."
  _prompt_action || return

  D="master_demo_dir_$$"

  cecho GREEN "a) D=\"master_demo_dir_\$\$\"; mkdir -p \"\$D\"; touch \"\$D\"/sample.txt; ls \"\$D\""
  mkdir -p "$D"
  touch "$D"/sample.txt
  ls -ld "$D"
  cecho GREEN "b) rm -rf \"\$D\"  # Cleanup"
  rm -rf "$D"
  echo "  Dir removed"
  cecho GREEN "c) mkdir -p \"\$D\" || { echo \"Failed\"; exit 1; }"
  (mkdir -p "$D" || { echo "Failed"; exit 1; }; echo "Success")
  rm -rf "$D" 2>/dev/null || true
  cecho GREEN "d) date +%Y%m%d_\$\$  # Unique name"
  date +%Y%m%d_$$
  _prompt_action || return

  cecho BLUE "------------------------------"
  cecho BOLD "2️⃣ ADVANCED: CHAINED TASKS"
  cecho BLUE "------------------------------"
  cat <<'EOF'
Example commands:
  a) D="task_$$"; mkdir -p "$D" && cd "$D" && touch {file1.txt,file2.log} && echo "All done in $D"
  b) (cd "$D" && tar -cf ../archive.tar *) || echo "Tar failed"; rm -rf "$D"
  c) set -e; mkdir "$D"; false; echo "Won't run"  → Exit on error
EOF
  read -p "Press ENTER to run advanced examples..."
  _prompt_action || return
  cecho GREEN "a) mkdir && cd && touch && echo"
  (D="task_$$"; mkdir -p "$D" && cd "$D" && touch {file1.txt,file2.log} && echo "All done in $D" && ls)
  rm -rf "$D" 2>/dev/null || true
  cecho GREEN "b) (cd && tar) || echo; rm"
  (D="task_$$"; mkdir -p "$D" && cd "$D" && touch file1.txt; (cd "$D" && tar -cf ../archive.tar *) || echo "Tar failed"; rm -rf "$D")
  cecho GREEN "c) set -e; mkdir; false; echo  # Exits early"
  (set -e; D="task_$$"; mkdir -p "$D"; false; echo "Won't run")
  _prompt_action || return

  # Full script demo
  cecho BLUE "------------------------------"
  cecho BOLD "3️⃣ FULL SCRIPT DEMO"
  cecho BLUE "------------------------------"
  read -p "Press ENTER to run the sample script..."
  _prompt_action || return
  chmod +x "$TMP_TEST_SCRIPT" 2>/dev/null
  ./"$TMP_TEST_SCRIPT"

  # Cleanup
  rm -f "$TMP_TEST_SCRIPT" ./backup_*.tar 2>/dev/null || true
  echo

  # Prompt to continue to next section (skips remaining sections if 'q')
  _prompt_action "Press ENTER to continue to next section, 'q' to skip remaining sections, 'Q' to quit: " || return 1
}

section_tips_shellcheck() {
  cecho BLUE "===================================================="
  cecho BOLD "💡 TIPS & BEST PRACTICES (SHELLCHECK)"
  cecho BLUE "===================================================="
  echo

  cecho WHITE '1. Shell Best Practices: Write robust, readable scripts'
  cecho WHITE '   - set -u: Treat unset vars as errors; IFS=$'\''\n\t'\'' : Safe splitting'
  cecho WHITE '   - Prefer "$()": Modern command substitution over ` `'
  cecho WHITE '   - Always quote vars: "$var" to prevent word splitting/glob issues'
  cecho WHITE '   - Use functions: Modularize code, minimize globals'
  cecho WHITE '2. Shellcheck: Linter for Bash scripts (install via apt/brew)'
  cecho WHITE '   - shellcheck script.sh: Scans for bugs, style issues, security'
  cecho WHITE '   - Ignore: # shellcheck disable=SC2034 (line-specific)'
  echo

  TMP_TEST_SCRIPT="./test_tips_shellcheck.sh"
  cat <<'EOF' > "$TMP_TEST_SCRIPT"
#!/bin/bash
# shellcheck source=/dev/null  # Good practice: explicit sourcing

set -u  # Treat unset vars as errors
IFS=$'\n\t'  # Safe IFS

# Function: Modular, quoted vars
greet() {
  local name="${1:-World}"  # Default param, local var
  echo "Hello, $name!"  # Quoted? Yes, but for output it's fine
}

# Modern sub: $(date) over `date`
backup() {
  local dir="backup_$(date +%Y%m%d)_$$"
  mkdir -p "$dir" || { echo "Error: mkdir $dir failed"; return 1; }
  touch "$dir"/data.txt
  echo "Backup in $dir"
}

# Call functions
greet "User"
backup

echo "Script complete (no set -e to continue on non-fatal errors)"
EOF

  cecho CYAN "Sample script created at: $TMP_TEST_SCRIPT"
  echo
  cat "$TMP_TEST_SCRIPT"
  echo
  _prompt_action || return

  cecho BLUE "------------------------------"
  cecho BOLD "1️⃣ BASIC TIPS"
  cecho BLUE "------------------------------"
  cat <<'EOF'
Example commands/tips:
  a) set -u; unset VAR; echo "$VAR"  → Errors on unset (good!)
  b) echo "$(date)"  → Modern sub over `date`
  c) for f in *; do echo "$f"; done  → Quote to avoid glob issues
  d) function func() { ... }; func args  → Modular code
EOF
  read -p "Press ENTER to run basic tips examples..."
  _prompt_action || return

  cecho GREEN "a) set -u; unset VAR; echo \"\$VAR\"  # Should error"
  (set -u; unset VAR; echo "$VAR") 2>&1 || echo "  ✓ Caught unset var"
  cecho GREEN "b) echo \"\$(date)\" vs \`date\`"
  echo "Modern: $(date)"
  echo "Legacy: `date`"
  cecho GREEN "c) Quote in loop: for f in *; do echo \"\$f\"; done"
  (for f in *; do echo "File: $f"; done | head -3)
  cecho GREEN "d) Simple function call"
  (greet() { echo "Func: $1"; }; greet "test")
  _prompt_action || return

  cecho BLUE "------------------------------"
  cecho BOLD "2️⃣ SHELLCHECK LINTING"
  cecho BLUE "------------------------------"
  cat <<'EOF'
Example commands:
  a) shellcheck -f gcc bad_script.sh  → GCC-like output
  b) echo '#!/bin/bash\nVAR=val\necho $VAR' > bad.sh; shellcheck bad.sh
  c) # shellcheck disable=SC2154  → Ignore specific warning
  d) shellcheck --exclude=SC2030 script.sh  → Global exclude
EOF
  read -p "Press ENTER to run shellcheck examples (assumes shellcheck installed)..."
  _prompt_action || return

  # Create a 'bad' example for demo
  cat <<'BAD' > ./bad_demo.sh
#!/bin/bash
VAR=hello
echo $VAR  # Unquoted!
`date`    # Legacy sub
rm -rf /  # Dangerous!
BAD

  cecho GREEN "a) shellcheck -f gcc on bad script"
  if command -v shellcheck >/dev/null 2>&1; then
    shellcheck -f gcc ./bad_demo.sh | head -5
  else
    echo "  shellcheck not installed; install with: apt install shellcheck"
  fi
  cecho GREEN "b) Quick bad script check"
  if command -v shellcheck >/dev/null 2>&1; then
    shellcheck ./bad_demo.sh
  else
    echo "  Skipping: shellcheck unavailable"
  fi
  cecho GREEN "c/d) Use disables/excludes in real scripts"
  echo "  See sample script above for good practices"
  rm -f ./bad_demo.sh
  _prompt_action || return

  # Full script demo
  cecho BLUE "------------------------------"
  cecho BOLD "3️⃣ FULL SCRIPT DEMO"
  cecho BLUE "------------------------------"
  read -p "Press ENTER to run the sample script..."
  _prompt_action || return
  chmod +x "$TMP_TEST_SCRIPT" 2>/dev/null
  ./"$TMP_TEST_SCRIPT"

  cecho BLUE "------------------------------"
  cecho BOLD "🔍 RUN SHELLCHECK ON SAMPLE"
  cecho BLUE "------------------------------"
  read -p "Press ENTER to lint the sample script (if shellcheck installed)..."
  _prompt_action || return
  if command -v shellcheck >/dev/null 2>&1; then
    cecho GREEN "shellcheck $TMP_TEST_SCRIPT"
    shellcheck "$TMP_TEST_SCRIPT" || echo "  (Warnings expected? Check output)"
  else
    cecho YELLOW "shellcheck not found - install it for linting!"
  fi

  # Cleanup
  rm -f "$TMP_TEST_SCRIPT" ./bad_demo.sh 2>/dev/null || true
  echo

  cecho BOLD "🎉 END OF DEMOS - Thanks for exploring Bash mastery!"
  echo "   Pro Tip: Always run 'shellcheck your_script.sh' before deploying."
  echo

  # Final prompt (no next section)
  read -p "Press ENTER to exit, or 'q' to quit: "
}

section_summary() {
  cecho BLUE "===================================================="
  cecho BOLD "📋 SUMMARY & RECAP"
  cecho BLUE "===================================================="
  echo

  cecho WHITE '1. What We Covered: Core Bash Mastery Topics'
  cecho WHITE '   - From basics (commands, file ops) to advanced (coproc, traps, regex)'
  cecho WHITE '   - Interactive demos: Run sections standalone or via runner for full flow'
  cecho WHITE '2. Execution Order: Runner processes sections as listed (customizable)'
  cecho WHITE '   - See SECTION_LIST in script for sequence; reorder for your learning path'
  cecho WHITE '3. Next Steps: Practice in real envs, integrate with tools like SSH keys'
  echo

  TMP_TEST_SCRIPT="./test_summary_runner.sh"
  cat <<'EOF' > "$TMP_TEST_SCRIPT"
#!/bin/bash

# Quick recap runner: Selectively run sections
declare -A SECTIONS=(
  ["1"]="BASIC LINUX + SYSTEM INFORMATION COMMANDS:section_basic_system_commands"
  ["2"]="FILE SEARCH & REPLACE:section_file_search"
  ["3"]="CONDITIONAL AND LOOPS:section_loops_conditions"
  ["4"]="SYSTEM VARIABLES:section_system_vars"
  ["5"]="PARAM EXPANSION & REGEX:section_parameter_expansion_regex"
  ["6"]="COMMAND SUBSTITUTION:section_command_subst"
  ["7"]="QUOTES & ESCAPING:section_quotes_escaping"
  ["8"]="FUNCTIONS & ARRAYS:section_functions_arrays"
  ["9"]="READ, GETOPTS & PRINTF:section_read_getopts_printf"
  ["10"]="REDIRECTION & FDS:section_redirection_fd"
  ["11"]="HEREDOC & PROCESS SUB:section_heredoc_procsub"
  ["12"]="ERROR HANDLING & TRAP:section_error_handling_trap"
  ["13"]="COPROC & JOB CONTROL:section_coproc_jobcontrol"
  ["14"]="MAPFILE / READARRAY:section_mapfile_readarray"
  ["15"]="AUTOMATION SAMPLE:section_automation_sample"
  ["16"]="REMOTE SINGLE-LINE DEMO (BANDIT):section_bandit_levels"
  ["17"]="TIPS & SHELLCHECK:section_tips_shellcheck"
)

echo "Bash Mastery Recap Runner"
echo "Available sections:"
for key in "${!SECTIONS[@]}"; do
  IFS=':' read -r title func <<< "${SECTIONS[$key]}"
  echo "  $key) $title"
done

read -p "Enter section numbers (comma-separated) or 'all' [q=quit]: " input
if [[ "$input" == "q" || "$input" == "Q" ]]; then
  echo "Exiting recap."
  exit 0
fi

if [[ "$input" == "all" ]]; then
  for entry in "${SECTIONS[@]}"; do
    IFS=':' read -r title func <<< "$entry"
    echo "Running: $title"
    "$func"  # Assume functions defined elsewhere
  done
else
  IFS=',' read -ra nums <<< "$input"
  for num in "${nums[@]}"; do
    if [[ -n "${SECTIONS[$num]}" ]]; then
      IFS=':' read -r title func <<< "${SECTIONS[$num]}"
      echo "Running: $title"
      "$func"
    else
      echo "Invalid: $num"
    fi
  done
fi

echo "Recap complete!"
EOF

  cecho CYAN "Sample recap runner created at: $TMP_TEST_SCRIPT"
  echo
  cat "$TMP_TEST_SCRIPT"
  echo
  _prompt_action || return

  cecho BLUE "------------------------------"
  cecho BOLD "1️⃣ TOPICS RECAP (Logical Order)"
  cecho BLUE "------------------------------"
  cat <<'EOF'
Covered in sequence:
  - BASIC LINUX + SYSTEM INFORMATION COMMANDS
  - FILE SEARCH & REPLACE
  - CONDITIONAL AND LOOPS
  - SYSTEM VARIABLES
  - PARAM EXPANSION & REGEX
  - COMMAND SUBSTITUTION
  - QUOTES & ESCAPING
  - FUNCTIONS & ARRAYS
  - READ, GETOPTS & PRINTF
  - REDIRECTION & FDS
  - HEREDOC & PROCESS SUB
  - ERROR HANDLING & TRAP
  - COPROC & JOB CONTROL
  - MAPFILE / READARRAY
  - AUTOMATION SAMPLE
  - REMOTE SINGLE-LINE DEMO (BANDIT)
  - TIPS & SHELLCHECK
EOF
  read -p "Press ENTER to see runner order..."
  _prompt_action || return

  cecho BLUE "------------------------------"
  cecho BOLD "2️⃣ RUNNER EXECUTION ORDER"
  cecho BLUE "------------------------------"
  echo "Current SECTION_LIST order (as in your script):"
  for entry in "${SECTION_LIST[@]}"; do
    title="${entry%%:*}"
    echo "  - $title"
  done
  echo
  cecho YELLOW "Tip: Reorder SECTION_LIST array for custom flow (e.g., basics first)."
  _prompt_action || return

  cecho BLUE "------------------------------"
  cecho BOLD "3️⃣ PRACTICE & NEXT STEPS"
  cecho BLUE "------------------------------"
  cat <<'EOF'
Hands-on Tips:
  a) Run full script via runner for interactive journey
  b) Test sections standalone: e.g., section_basic_system_commands
  c) Real-world: Use SSH keys (ssh-keygen; ssh-copy-id) for passwordless automation
  d) Debug: Add set -x for tracing; always shellcheck!
  e) Extend: Build a personal tool, like a log parser with mapfile + regex
EOF
  read -p "Press ENTER to run recap runner demo..."
  _prompt_action || return
  chmod +x "$TMP_TEST_SCRIPT" 2>/dev/null
  ./"$TMP_TEST_SCRIPT"

  # Full script demo (but it's the runner itself)
  cecho BLUE "------------------------------"
  cecho BOLD "🎓 FINAL RECAP DEMO"
  cecho BLUE "------------------------------"
  echo "The sample above is a mini-runner: Try 'all' or pick numbers!"
  echo

  # Cleanup
  rm -f "$TMP_TEST_SCRIPT" 2>/dev/null || true
  echo

  cecho BOLD "🚀 BASH MASTERY COMPLETE!"
  cecho GREEN "Practice regularly, contribute to open-source scripts, and automate your world."
  echo

  # Final prompt (end of script)
  read -p "Press ENTER to exit: "
}

main() {
  # Note: main() is kept for backward compatibility, but the runner below uses run_section for interactivity.
  # You can call main directly if needed, but recommend using the runner.
 section_summary
 section_tips_shellcheck
 section_automation_sample
 section_mapfile_readarray
  section_coproc_jobcontrol
 section_error_handling_trap
  section_heredoc_procsub
  section_redirection_fd
  section_read_getopts_printf
  section_functions_arrays
  section_quotes_escaping
  section_command_subst
  section_bandit_levels
  section_basic_system_commands
  section_file_search
  section_parameter_expansion_regex
  section_system_vars
  section_loops_conditions
}

# ---- Runner ----
SECTION_LIST=(
  "BASIC LINUX + SYSTEM INFORMATION COMMANDS:section_basic_system_commands"
  "FILE SEARCH & REPLACE:section_file_search"
  "SHELL BUILTIN COMMANDS:section_builtin_functions"
  "ARITHMETIC OPERATIONS:section_arithmetic_operations"
  "CONDITIONAL AND LOOPS:section_loops_conditions"
  "SYSTEM VARIABLES:section_system_vars"
  "PARAM EXPANSION & REGEX:section_parameter_expansion_regex"
  "COMMAND SUBSTITUTION:section_command_subst"
  "QUOTES & ESCAPING:section_quotes_escaping"
  "FUNCTIONS & ARRAYS:section_functions_arrays"
  "READ, GETOPTS & PRINTF:section_read_getopts_printf"
  "REDIRECTION & FDS:section_redirection_fd"
  "HEREDOC & PROCESS SUB:section_heredoc_procsub"
  "ERROR HANDLING & TRAP:section_error_handling_trap"
  "COPROC & JOB CONTROL:section_coproc_jobcontrol"
  "MAPFILE / READARRAY:section_mapfile_readarray"
  "AUTOMATION SAMPLE:section_automation_sample"
  "REMOTE SINGLE-LINE DEMO (BANDIT):section_bandit_levels"
  "TIPS & SHELLCHECK:section_tips_shellcheck"
  "SUMMARY:section_summary"
)

# Print TOC at the start
print_toc

# Index-based loop to allow jumping
for ((i=0; i<${#SECTION_LIST[@]}; i++)); do
  # Check for jump request
  if [[ -n "${JUMP_TO_TARGET:-}" ]]; then
    # Validate target again to be safe
    if (( JUMP_TO_TARGET >= 1 && JUMP_TO_TARGET <= ${#SECTION_LIST[@]} )); then
       # Update index to target-1 (because loop does i++ after this iteration)
       # But since we want to Run the target immediately, we set i = target - 1.
       # And we need to ensure we don't process the *current* entry if we just jumped?
       # Actually, logic:
       # If JUMP_TO_TARGET is set, we adjust 'i'.
       i=$((JUMP_TO_TARGET - 1))
       JUMP_TO_TARGET="" # Clear request
    fi
  fi

  entry="${SECTION_LIST[$i]}"
  title="${entry%%:*}"
  func="${entry#*:}"
  run_section "$title" "$func"
  
  # Check if jump was set inside run_section
  if [[ -n "${JUMP_TO_TARGET:-}" ]]; then
     # Decrement i so that next iteration starts at the new target
     # The loop will do i++, so we set i = target - 2 (effectively) ??
     # No, better logic:
     # We check JUMP_TO_TARGET at start of loop.
     # If prompt set it, run_section returned. Loop iterates. i increments.
     # So next iteration: 'i' needs to be (target - 1).
     # So we subtract 1 from target, then subtract 1 more to account for loop increment?
     # Wait. A `for` loop increments `i` *after* the body.
     # So if we set i = target - 2, next is target - 1.
     i=$((JUMP_TO_TARGET - 2))
     # If we are jumping from 1 to 14. Target=14.
     # We want next iteration to be i=13 (which is item 14).
     # Loop does i++. So we need i=12.
     # So i = target - 2.
  fi
done

echo
cecho GREEN "All sections processed. Cleaning up..."
cleanup
cecho GREEN "Done."
